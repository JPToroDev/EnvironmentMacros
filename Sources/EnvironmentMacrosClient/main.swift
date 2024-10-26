//import EnvironmentMacros

import EnvironmentMacros
import Foundation

@EnvironmentBodyBuilder
struct ExampleView {
    var isProduction: Bool
    
    var body: String {
        if isProduction {
            "Production Mode"
        } else {
            "Development Mode"
        }
    }
}
