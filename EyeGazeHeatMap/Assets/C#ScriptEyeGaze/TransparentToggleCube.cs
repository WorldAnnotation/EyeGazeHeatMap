using UnityEngine;

public class TransparentToggleCube : MonoBehaviour
{
    public GameObject cube; // 透明にするCubeを指定
    public KeyCode toggleKey = KeyCode.T; // 透明に切り替えるキー

    private bool isTransparent = false; // 現在の透明状態を追跡

    void Update()
    {
        if (Input.GetKeyDown(toggleKey))
        {
            ToggleTransparency();
        }
    }

    void ToggleTransparency()
    {
        Renderer cubeRenderer = cube.GetComponent<Renderer>();
        if (cubeRenderer != null)
        {
            Color color = cubeRenderer.material.color;
            isTransparent = !isTransparent; // 透明状態を切り替え
            color.a = isTransparent ? 0 : 1; // アルファを0または1に設定
            cubeRenderer.material.color = color;
        }
    }
}
