package et.myedu.staff

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "et.myedu/autofill"
    private var pendingCredentials: Map<String, String>? = null
    private var channel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val schoolCode = intent.getStringExtra("school_code")
        val username = intent.getStringExtra("username")
        val password = intent.getStringExtra("password")
        val role = intent.getStringExtra("role")

        if (schoolCode != null || username != null || password != null) {
            val creds = mutableMapOf<String, String>()
            if (schoolCode != null) creds["school_code"] = schoolCode
            if (username != null) creds["username"] = username
            if (password != null) creds["password"] = password
            if (role != null) creds["role"] = role
            pendingCredentials = creds

            channel?.invokeMethod("onAutofillReceived", creds)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getAutofillCredentials" -> {
                    val creds = pendingCredentials
                    pendingCredentials = null
                    result.success(creds)
                }
                "clearAutofillCredentials" -> {
                    pendingCredentials = null
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
