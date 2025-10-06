package com.spendly.app

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager
import android.os.Build
import android.util.Log

class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable hardware acceleration and high refresh rate optimizations
        enablePerformanceOptimizations()
    }

    private fun enablePerformanceOptimizations() {
        try {
            // Enable hardware acceleration
            window.addFlags(WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED)
            
            // For Android 11 and above, try to enable high refresh rate
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // Request highest refresh rate available
                window.attributes = window.attributes.apply {
                    preferredRefreshRate = 120f // Request 120Hz if available
                }
                Log.d(TAG, "Requested 120Hz refresh rate")
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // For older Android versions, try alternative approach
                val windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
                val display = windowManager.defaultDisplay
                
                val supportedModes = display.supportedModes
                var highestRefreshRate = 60.0f
                var bestModeId = -1
                
                Log.d(TAG, "Available display modes:")
                for (mode in supportedModes) {
                    Log.d(TAG, "Mode ${mode.modeId}: ${mode.refreshRate}Hz")
                    if (mode.refreshRate > highestRefreshRate) {
                        highestRefreshRate = mode.refreshRate
                        bestModeId = mode.modeId
                    }
                }
                
                if (highestRefreshRate > 60.0f && bestModeId != -1) {
                    window.attributes = window.attributes.apply {
                        preferredDisplayModeId = bestModeId
                    }
                    Log.d(TAG, "Set to ${highestRefreshRate}Hz mode")
                }
            }
            
            Log.d(TAG, "Performance optimizations applied")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to apply performance optimizations", e)
        }
    }
}