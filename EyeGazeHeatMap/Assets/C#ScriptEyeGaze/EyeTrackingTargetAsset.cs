// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using System;
using System.Collections.Generic;
using System.Collections;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Serialization;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

using System.Threading;
using System.Net.Http;
using System.IO;
using System;
using System.Net.Http.Headers;
using System.Threading.Tasks;

using Microsoft.MixedReality.Toolkit.Input;
using System.Linq;

namespace Microsoft.MixedReality.Toolkit.Input
{

    public struct FetchedData
    {
        public int x;
        public int y;
        public double value;

        public FetchedData(int x, int y, double value)
        {
            this.x = x;
            this.y = y;
            this.value = value;
        }
    }

    /// <summary>
    /// A game object with the "EyeTrackingTarget" script attached reacts to being looked at independent of other available inputs.
    /// </summary>
    [AddComponentMenu("Scripts/MRTK/SDK/EyeTrackingTarget")]
    public class EyeTrackingTargetAsset : InputSystemGlobalHandlerListener, IMixedRealityPointerHandler, IMixedRealitySpeechHandler
    {
        CancellationTokenSource cancellationTokenSource;
        HttpResponseMessage httpResponse;
        StreamReader contentStreamReader;
        Stream contentStream;
        Task taskFirebase;

        [Tooltip("Select action that are specific to when the target is looked at.")]
        [SerializeField]
        private MixedRealityInputAction selectAction = MixedRealityInputAction.None;

        [Tooltip("List of voice commands to trigger selecting this target only if it is looked at.")]
        [SerializeField]
        [FormerlySerializedAs("voice_select")]
        private MixedRealityInputAction[] voiceSelect = null;

        [Tooltip("Duration in seconds that the user needs to keep looking at the target to select it via dwell activation.")]
        [Range(0, 10)]
        [SerializeField]
        private float dwellTimeInSec = 0.8f;

        [SerializeField]
        [Tooltip("Event is triggered when the user starts to look at the target.")]
        [FormerlySerializedAs("OnLookAtStart")]
        private UnityEvent onLookAtStart = null;

        /// <summary>
        /// Event is triggered when the user starts to look at the target.
        /// </summary>
        public UnityEvent OnLookAtStart
        {
            get { return onLookAtStart; }
            set { onLookAtStart = value; }
        }

        [SerializeField]
        [Tooltip("Event is triggered when the user continues to look at the target.")]
        [FormerlySerializedAs("WhileLookingAtTarget")]
        private UnityEvent whileLookingAtTarget = null;

        /// <summary>
        /// Event is triggered when the user continues to look at the target.
        /// </summary>
        public UnityEvent WhileLookingAtTarget
        {
            get { return whileLookingAtTarget; }
            set { whileLookingAtTarget = value; }
        }

        [SerializeField]
        [Tooltip("Event to be triggered when the user is looking away from the target.")]
        [FormerlySerializedAs("OnLookAway")]
        private UnityEvent onLookAway = null;

        /// <summary>
        /// Event to be triggered when the user is looking away from the target.
        /// </summary>
        public UnityEvent OnLookAway
        {
            get { return onLookAway; }
            set { onLookAway = value; }
        }

        [SerializeField]
        [Tooltip("Event is triggered when the target has been looked at for a given predefined duration (dwellTimeInSec).")]
        [FormerlySerializedAs("OnDwell")]
        private UnityEvent onDwell = null;

        /// <summary>
        /// Event is triggered when the target has been looked at for a given predefined duration (dwellTimeInSec).
        /// </summary>
        public UnityEvent OnDwell
        {
            get { return onDwell; }
            set { onDwell = value; }
        }

        [SerializeField]
        [Tooltip("Event is triggered when the looked at target is selected.")]
        [FormerlySerializedAs("OnSelected")]
        private UnityEvent onSelected = null;

        /// <summary>
        /// Event is triggered when the looked at target is selected.
        /// </summary>
        public UnityEvent OnSelected
        {
            get { return onSelected; }
            set { onSelected = value; }
        }

        [SerializeField]
        private UnityEvent onTapDown = new UnityEvent();

        /// <summary>
        /// Event is triggered when the RaiseEventManually_TapDown is called.
        /// </summary>
        public UnityEvent OnTapDown
        {
            get { return onTapDown; }
            set { onTapDown = value; }
        }

        [SerializeField]
        private UnityEvent onTapUp = new UnityEvent();

        /// <summary>
        /// Event is triggered when the RaiseEventManually_TapUp is called.
        /// </summary>
        public UnityEvent OnTapUp
        {
            get { return onTapUp; }
            set { onTapUp = value; }
        }

        [SerializeField]
        [Tooltip("If true, the eye cursor (if enabled) will snap to the center of this object.")]
        private bool eyeCursorSnapToTargetCenter = false;

        /// <summary>
        /// If true, the eye cursor (if enabled) will snap to the center of this object.
        /// </summary>
        public bool EyeCursorSnapToTargetCenter
        {
            get { return eyeCursorSnapToTargetCenter; }
            set { eyeCursorSnapToTargetCenter = value; }
        }

        /// <summary>
        /// Returns true if the user looks at the target or more specifically when the eye gaze ray intersects
        /// with the target's bounding box.
        /// </summary>
        public bool IsLookedAt { get; private set; }

        /// <summary>
        /// Returns true if the user has been looking at the target for a certain amount of time specified by dwellTimeInSec.
        /// </summary>
        public bool IsDwelledOn { get; private set; } = false;

        private DateTime lookAtStartTime;

        /// <summary>
        /// Duration in milliseconds to indicate that if more time than this passes without new eye tracking data, then timeout.
        /// </summary>
        private float EyeTrackingTimeoutInMilliseconds = 200;

        /// <summary>
        /// The time stamp received from the eye tracker to indicate when the eye tracking signal was last updated.
        /// </summary>
        private static DateTime lastEyeSignalUpdateTimeFromET = DateTime.MinValue;

        /// <summary>
        /// The time stamp from the eye tracker has its own time frame, which makes it difficult to compare to local times.
        /// </summary>
        private static DateTime lastEyeSignalUpdateTimeLocal = DateTime.MinValue;

        private DateTime lastTimeClicked;
        private float minTimeoutBetweenClicksInMs = 20f;

        /// <summary>
        /// GameObject eye gaze is currently targeting, updated once per frame.
        /// null if no object with collider is currently being looked at.
        /// </summary>
        public static GameObject LookedAtTarget =>
            (CoreServices.InputSystem != null &&
            CoreServices.InputSystem.EyeGazeProvider != null &&
            CoreServices.InputSystem.EyeGazeProvider.IsEyeTrackingEnabledAndValid) ? CoreServices.InputSystem.EyeGazeProvider.GazeTarget : null;

        /// <summary>
        /// The point in space where the eye gaze hit.
        /// set to the origin if the EyeGazeProvider is not currently enabled
        /// </summary>
        public static Vector3 LookedAtPoint =>
            (CoreServices.InputSystem != null &&
            CoreServices.InputSystem.EyeGazeProvider != null &&
            CoreServices.InputSystem.EyeGazeProvider.IsEyeTrackingEnabledAndValid) ? CoreServices.InputSystem.EyeGazeProvider.HitPosition : Vector3.zero;

        /// <summary>
        /// EyeTrackingTarget eye gaze is currently looking at.
        /// null if currently gazed at object has no EyeTrackingTarget, or if
        /// no object with collider is being looked at.
        /// </summary>
        public static EyeTrackingTarget LookedAtEyeTarget { get; private set; }

        /// <summary>
        /// Most recently selected target, selected either using pointer
        /// or voice.
        /// </summary>
        public static GameObject SelectedTarget { get; set; }

        #region Focus handling
        protected override void Start()
        {
            GetAndProcessFirebaseHttpResponse(JsonConvert.SerializeObject(isVisibleList), "https://eyegazeheatmap-default-rtdb.asia-southeast1.firebasedatabase.app/isVisibleList.json", "PUT");
            base.Start();
            IsLookedAt = false;
            LookedAtEyeTarget = null;
        }

        static private bool[] isVisibleList = { true, true, true };
        private void Update()
        {
            // Try to manually poll the eye tracking data
            if ((CoreServices.InputSystem != null) && (CoreServices.InputSystem.EyeGazeProvider != null) &&
                CoreServices.InputSystem.EyeGazeProvider.IsEyeTrackingEnabled &&
                CoreServices.InputSystem.EyeGazeProvider.IsEyeTrackingDataValid)
            {
                UpdateHitTarget();

                bool isLookedAtNow = (LookedAtTarget == this.gameObject);

                if (IsLookedAt && (!isLookedAtNow))
                {
                    // Stopped looking at the target
                    OnEyeFocusStop();
                }
                else if ((!IsLookedAt) && (isLookedAtNow))
                {
                    // Started looking at the target
                    OnEyeFocusStart();
                }
                else if (IsLookedAt && (isLookedAtNow))
                {
                    // Keep looking at the target
                    OnEyeFocusStay();
                }

                var localPoint = transform.InverseTransformPoint(LookedAtPoint); //���[���h���W�Ƃ��Ď擾����LookAtPoint��TargetPlane��̑��Έʒu(localpoint)�Ƃ��Ċi�[
                if (UnityEngine.Input.anyKeyDown)
                {
                    switch (UnityEngine.Input.inputString)
                    {
                        case "r":
                            isRecording = !isRecording;
                            Debug.Log("Toggled!!!!!");

                            // ���R�[�f�B���O�J�n����recordingJson��������
                            if (isRecording)
                            {
                                recordingJson = new JObject();
                            }
                            break;
                        case "1":
                            toggleCubeVisible("0");
                            break;
                        case "2":
                            toggleCubeVisible("1");
                            break;
                        case "3":
                            toggleCubeVisible("2");
                            break;
                        case " ":
                            toggleCubeVisible(" ");
                            break;

                    }
                    if (UnityEngine.Input.inputString == "r")
                    {
                        // TODO: ���R�[�f�B���O�������I�u�W�F�N�g��\��
                    }
                }
                PostHeatMapHandler(localPoint);
            }
        }

        private void toggleCubeVisible(string key)
        {
            if (key == " ")
            {
                for (int i = 0; i < isVisibleList.Length; i++)
                {
                    isVisibleList[i] = !isVisibleList[i];
                }
            }
            else
            {
                isVisibleList[int.Parse(key)] = !isVisibleList[int.Parse(key)];
            }
            string isVisiblejson = JsonConvert.SerializeObject(isVisibleList);
            GetAndProcessFirebaseHttpResponse(isVisiblejson, "https://eyegazeheatmap-default-rtdb.asia-southeast1.firebasedatabase.app/isVisibleList.json", "PUT");
        }

        static private int frameCount = 0;
        static private List<Vector2> localPointDataList = new List<Vector2>();


        private static bool isRecording = false;
        private static JObject recordingJson = new JObject();


        private void PostHeatMapHandler(Vector3 localPoint)
        {
            frameCount++;

            // Add the local point to heat map data list if frameCount is not 60.
            // This ensures that every 60 frames (which is every second at 60fps),
            // you do not add the new point, allowing for the heatmap processing.
            float x = localPoint.x + float.Parse("0.5");
            float z = localPoint.z + float.Parse("0.5");
            localPointDataList.Add(new Vector2(x, z));

            // If frameCount has reached 60 (1 second), process the heatmap data.
            if (frameCount >= 60)
            {
                // Reset frame count.
                frameCount = 0;

                // Check if we have 5 seconds worth of data to generate heatmap.
                if (localPointDataList.Count >= 300) // 60fps * 5s = 300 frames
                {
                    localPointDataList.RemoveRange(0, localPointDataList.Count - 300);

                    // Generate the heatmap data.
                    List<FetchedData> heatMapData = GenerateHeatMap(1, 1, 0, 0); // Placeholder for heatmap generation logic.
                    // Post the heatmap data to Firebase.s
                    PutFirebase(heatMapData);

                    // Remove the oldest data to keep the list size to last 5 seconds worth of data.
                }
            }
        }


        private List<FetchedData> GenerateHeatMap(double x_max, double y_max, double x_min, double y_min)
        {
            var heatmapData = new Dictionary<Tuple<int, int>, FetchedData>();
            double gridWidth = (x_max - x_min) / 80;
            double gridHeight = (y_max - y_min) / 60;

            for (int i = 0; i < localPointDataList.Count; i++)
            {
                double adjustedX = localPointDataList[i].x - x_min;
                double adjustedY = localPointDataList[i].y - y_min;
                int col = Math.Clamp((int)(adjustedX / gridWidth), 0, 79);
                int row = Math.Clamp((int)(adjustedY / gridHeight), 0, 59);

                int density = (int)(100.0 / 300 * i);
                if (density > 0)
                {
                    var key = Tuple.Create(col, row);
                    if (heatmapData.ContainsKey(key))
                    {
                        var existingData = heatmapData[key];
                        existingData.value = density; // ここで一時変数の値を変更
                        heatmapData[key] = existingData; // 変更された値を Dictionary に戻す
                    }
                    else
                    {
                        heatmapData.Add(key, new FetchedData { x = col, y = row, value = density });
                    }
                }
            }
            return heatmapData.Values.ToList();
        }



        private void PutFirebase(List<FetchedData> heatMapData)
        {
            // ヒートマップデータをJSON形式にシリアライズ
            string json = JsonConvert.SerializeObject(heatMapData);

            if (isRecording)
            {
                // レコーディング中の処理
                string timestamp = DateTime.Now.ToString("yyyyMMddHHmmss");
                recordingJson[timestamp] = new JObject();
                recordingJson[timestamp]["heatmap"] = JToken.Parse(json);
                recordingJson[timestamp]["isCubeVisibility"] = JToken.FromObject(isVisibleList);
            }
            else if (recordingJson.Count > 0)
            {
                // レコーディング終了後の処理
                Debug.Log(recordingJson.ToString());
                GetAndProcessFirebaseHttpResponse(recordingJson.ToString(), "https://eyegazeheatmap-default-rtdb.asia-southeast1.firebasedatabase.app/logs/" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".json", "PUT");
                recordingJson = new JObject(); // レコーディングJSONをリセット
            }
            Debug.Log(json);
            // ヒートマップデータをFirebaseに送信
            GetAndProcessFirebaseHttpResponse(json, "https://eyegazeheatmap-default-rtdb.asia-southeast1.firebasedatabase.app/images/image2.json", "PUT");
        }




        public void GetAndProcessFirebaseHttpResponse(string json, string path, string method)
        {
            taskFirebase = new Task(async () =>
            {
                cancellationTokenSource = new CancellationTokenSource();

                try
                {
                    switch (method)
                    {
                        case "PUT":
                            // PutDataAsync���\�b�h����x�����Ăяo��
                            httpResponse = await PutDataAsync(json, path);
                            break;
                        case "POST":
                            // PutDataAsync���\�b�h����x�����Ăяo��
                            httpResponse = await PostDataAsync(json, path);
                            break;
                    }


                    // �����̏����i���O�o�͂Ȃǁj
                    if (httpResponse.IsSuccessStatusCode)
                    {
                        Debug.Log("Data successfully updated.");
                    }
                }
                catch (Exception e)
                {
                    Debug.LogError("Error during HTTP request: " + e.Message);
                }
            });

            taskFirebase.Start();
        }

        private async Task<HttpResponseMessage> PutDataAsync(string json, string path)
        {
            HttpClientHandler httpClientHandler = new HttpClientHandler();
            httpClientHandler.AllowAutoRedirect = true;

            var firebasePath = path;

            using (HttpClient httpClient = new HttpClient(httpClientHandler, true))
            {
                httpClient.BaseAddress = new Uri(firebasePath);
                httpClient.Timeout = TimeSpan.FromSeconds(60);

                StringContent content = new StringContent(json, Encoding.UTF8, "application/json");
                HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Put, firebasePath)
                {
                    Content = content
                };

                HttpResponseMessage response = await httpClient.SendAsync(request, HttpCompletionOption.ResponseHeadersRead).ConfigureAwait(false);
                Debug.Log(response);
                response.EnsureSuccessStatusCode();

                return response;
            }
        }
        private async Task<HttpResponseMessage> PostDataAsync(string json, string path)
        {
            HttpClientHandler httpClientHandler = new HttpClientHandler();
            httpClientHandler.AllowAutoRedirect = true;

            var firebasePath = path;

            using (HttpClient httpClient = new HttpClient(httpClientHandler, true))
            {
                httpClient.BaseAddress = new Uri(firebasePath);
                httpClient.Timeout = TimeSpan.FromSeconds(60);

                StringContent content = new StringContent(json, Encoding.UTF8, "application/json");
                HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Put, firebasePath)
                {
                    Content = content
                };

                HttpResponseMessage response = await httpClient.SendAsync(request, HttpCompletionOption.ResponseHeadersRead).ConfigureAwait(false);
                response.EnsureSuccessStatusCode();

                return response;
            }
        }


        protected override void OnDisable()
        {
            base.OnDisable();
            OnEyeFocusStop();
        }

        /// <inheritdoc/>
        protected override void RegisterHandlers()
        {
            CoreServices.InputSystem?.RegisterHandler<IMixedRealityPointerHandler>(this);
            CoreServices.InputSystem?.RegisterHandler<IMixedRealitySpeechHandler>(this);
        }
        /// <inheritdoc/>
        protected override void UnregisterHandlers()
        {
            CoreServices.InputSystem?.UnregisterHandler<IMixedRealityPointerHandler>(this);
            CoreServices.InputSystem?.UnregisterHandler<IMixedRealitySpeechHandler>(this);
        }

        private void UpdateHitTarget()
        {
            if (lastEyeSignalUpdateTimeFromET != CoreServices.InputSystem?.EyeGazeProvider?.Timestamp)
            {
                if ((CoreServices.InputSystem != null) && (CoreServices.InputSystem.EyeGazeProvider != null))
                {
                    lastEyeSignalUpdateTimeFromET = (CoreServices.InputSystem?.EyeGazeProvider?.Timestamp).Value;
                    lastEyeSignalUpdateTimeLocal = DateTime.UtcNow;

                    if (LookedAtTarget != null)
                    {
                        LookedAtEyeTarget = LookedAtTarget.GetComponent<EyeTrackingTarget>();
                    }
                }
            }
            else if ((DateTime.UtcNow - lastEyeSignalUpdateTimeLocal).TotalMilliseconds > EyeTrackingTimeoutInMilliseconds)
            {
                LookedAtEyeTarget = null;
            }
        }

        protected void OnEyeFocusStart()
        {
            lookAtStartTime = DateTime.UtcNow;
            IsLookedAt = true;
            OnLookAtStart?.Invoke();
        }

        protected void OnEyeFocusStay()
        {
            WhileLookingAtTarget?.Invoke();

            if ((!IsDwelledOn) && (DateTime.UtcNow - lookAtStartTime).TotalSeconds > dwellTimeInSec)
            {
                OnEyeFocusDwell();
            }
        }

        protected void OnEyeFocusDwell()
        {
            IsDwelledOn = true;
            OnDwell?.Invoke();
        }

        protected void OnEyeFocusStop()
        {
            IsDwelledOn = false;
            IsLookedAt = false;
            OnLookAway?.Invoke();
        }

        #endregion

        #region IMixedRealityPointerHandler
        void IMixedRealityPointerHandler.OnPointerUp(MixedRealityPointerEventData eventData) { }

        void IMixedRealityPointerHandler.OnPointerDown(MixedRealityPointerEventData eventData) { }

        void IMixedRealityPointerHandler.OnPointerDragged(MixedRealityPointerEventData eventData) { }

        void IMixedRealityPointerHandler.OnPointerClicked(MixedRealityPointerEventData eventData)
        {
            if ((eventData.MixedRealityInputAction == selectAction) && IsLookedAt && ((DateTime.UtcNow - lastTimeClicked).TotalMilliseconds > minTimeoutBetweenClicksInMs))
            {
                lastTimeClicked = DateTime.UtcNow;
                EyeTrackingTarget.SelectedTarget = this.gameObject;
                OnSelected.Invoke();
            }
        }

        void IMixedRealitySpeechHandler.OnSpeechKeywordRecognized(SpeechEventData eventData)
        {
            if ((IsLookedAt) && (this.gameObject == LookedAtTarget))
            {
                if (voiceSelect != null)
                {
                    for (int i = 0; i < voiceSelect.Length; i++)
                    {
                        if (eventData.MixedRealityInputAction == voiceSelect[i])
                        {
                            EyeTrackingTarget.SelectedTarget = this.gameObject;
                            OnSelected.Invoke();
                        }
                    }
                }
            }
        }
        #endregion

        #region Methods to Invoke Events Manually
        public void RaiseSelectEventManually()
        {
            EyeTrackingTarget.SelectedTarget = this.gameObject;
            OnSelected.Invoke();
        }
        #endregion
    }
}
