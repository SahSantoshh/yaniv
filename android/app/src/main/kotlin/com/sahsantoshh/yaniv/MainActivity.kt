package com.sahsantoshh.yaniv

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity is a ComponentActivity, so enableEdgeToEdge() is the
// API Play Console looks for on Android 14 and below. Android 15+ is already
// edge-to-edge when targetSdk is 35+.
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
