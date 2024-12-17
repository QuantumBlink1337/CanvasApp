//
//  ScoreStatistic.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/12/24.
//

import Foundation


struct ScoreStatistic : Decodable {
    var min: Float
    var max: Float
    var mean: Float
    var upperQuartile: Float
    var median: Float
    var lowerQuartile: Float
    
    private enum CodingKeys: String, CodingKey {
        case min
        case max
        case mean
        case upperQuartile = "upper_q"
        case median
        case lowerQuartile = "lower_q"
    }
}
