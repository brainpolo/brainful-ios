//
//  BrainfulWidgetBundle.swift
//  BrainfulWidget
//
//  Created by Aditya STANDARD on 23/03/2025.
//

import WidgetKit
import SwiftUI

@main
struct BrainfulWidgetBundle: WidgetBundle {
    var body: some Widget {
        BrainfulWidget()
        BrainfulWidgetControl()
        BrainfulWidgetLiveActivity()
    }
}
