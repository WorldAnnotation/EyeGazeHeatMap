    //
    //  HeatmapData.swift
    //  EyeGazeDisplay
    //
    //  Created by 河口欣仁 on 2023/10/27.
    //

    struct HeatmapData{
        let rows: Int
        let columns: Int
        var data: [[Int]]
    }

    struct FetchedData {
        let value: Int
        let x: Int
        let y: Int
    }
