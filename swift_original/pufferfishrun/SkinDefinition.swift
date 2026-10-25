//
//  SkinDefinition.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import SpriteKit

struct SkinDefinition {
    let id: String
    let name: String
    let unlockScore: Int
    let bodyColor: SKColor
    let bellyColor: SKColor
    let spineColor: SKColor
    let eyeColor: SKColor
    let tailColor: SKColor
}

let SKINS: [SkinDefinition] = [
    SkinDefinition(
        id: "default", name: "PUFFERFISH",
        unlockScore: 0,
        bodyColor: SKColor(red:0.957,green:0.659,blue:0.196,alpha:1),
        bellyColor: SKColor(red:0.941,green:0.471,blue:0.125,alpha:1),
        spineColor: SKColor(red:1.0,green:0.976,blue:0.902,alpha:1),
        eyeColor: SKColor(red:0.290,green:0.565,blue:0.851,alpha:1),
        tailColor: SKColor(red:0.957,green:0.573,blue:0.102,alpha:1)
    ),
    SkinDefinition(
        id: "ghost", name: "GHOST",
        unlockScore: 10,
        bodyColor: SKColor(red:0.863,green:0.910,blue:0.941,alpha:1),
        bellyColor: SKColor(red:0.722,green:0.816,blue:0.878,alpha:1),
        spineColor: SKColor(red:1.0,green:1.0,blue:1.0,alpha:1),
        eyeColor: SKColor(red:1.0,green:0.267,blue:0.267,alpha:1),
        tailColor: SKColor(red:0.784,green:0.863,blue:0.910,alpha:1)
    ),
    SkinDefinition(
        id: "lava", name: "LAVA",
        unlockScore: 20,
        bodyColor: SKColor(red:0.910,green:0.251,blue:0.125,alpha:1),
        bellyColor: SKColor(red:0.753,green:0.125,blue:0.063,alpha:1),
        spineColor: SKColor(red:1.0,green:0.667,blue:0.0,alpha:1),
        eyeColor: SKColor(red:1.0,green:1.0,blue:0.0,alpha:1),
        tailColor: SKColor(red:0.753,green:0.188,blue:0.063,alpha:1)
    ),
    SkinDefinition(
        id: "ocean", name: "DEEP SEA",
        unlockScore: 35,
        bodyColor: SKColor(red:0.102,green:0.416,blue:0.667,alpha:1),
        bellyColor: SKColor(red:0.051,green:0.290,blue:0.478,alpha:1),
        spineColor: SKColor(red:0.533,green:0.867,blue:1.0,alpha:1),
        eyeColor: SKColor(red:0.0,green:1.0,blue:0.667,alpha:1),
        tailColor: SKColor(red:0.051,green:0.290,blue:0.478,alpha:1)
    ),
    SkinDefinition(
        id: "gold", name: "GOLDEN",
        unlockScore: 50,
        bodyColor: SKColor(red:0.969,green:0.761,blue:0.204,alpha:1),
        bellyColor: SKColor(red:0.878,green:0.627,blue:0.125,alpha:1),
        spineColor: SKColor(red:1.0,green:0.980,blue:0.800,alpha:1),
        eyeColor: SKColor(red:1.0,green:0.400,blue:0.0,alpha:1),
        tailColor: SKColor(red:0.878,green:0.627,blue:0.125,alpha:1)
    ),
    SkinDefinition(
        id: "shadow", name: "SHADOW",
        unlockScore: 75,
        bodyColor: SKColor(red:0.102,green:0.102,blue:0.180,alpha:1),
        bellyColor: SKColor(red:0.051,green:0.051,blue:0.102,alpha:1),
        spineColor: SKColor(red:0.608,green:0.349,blue:0.714,alpha:1),
        eyeColor: SKColor(red:0.608,green:0.349,blue:0.714,alpha:1),
        tailColor: SKColor(red:0.051,green:0.051,blue:0.102,alpha:1)
    ),
]
