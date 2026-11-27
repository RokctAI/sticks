package com.app.demo

import android.os.Build
import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.DisconnectCause
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import androidx.annotation.RequiresApi

/**
 * The self-managed call behind a Sticks voice session. Telecom routes its
 * audio to Bluetooth call audio when a headset or watch is connected.
 */
@RequiresApi(Build.VERSION_CODES.O)
class SticksConnectionService : ConnectionService() {
    companion object {
        var callerName: String = "Sticks"
        private var active: Connection? = null

        fun endActive() {
            val c = active ?: return
            active = null
            c.setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
            c.destroy()
        }
    }

    override fun onCreateOutgoingConnection(
        account: PhoneAccountHandle?,
        request: ConnectionRequest?,
    ): Connection {
        val c = object : Connection() {
            override fun onDisconnect() = hangUp(DisconnectCause.REMOTE)
            override fun onAbort() = hangUp(DisconnectCause.CANCELED)
            private fun hangUp(cause: Int) {
                if (active === this) active = null
                setDisconnected(DisconnectCause(cause))
                destroy()
                SticksCallBridge.notifyEnded()
            }
        }
        c.connectionProperties = Connection.PROPERTY_SELF_MANAGED
        c.audioModeIsVoip = true
        c.setAddress(request?.address, TelecomManager.PRESENTATION_ALLOWED)
        c.setCallerDisplayName(callerName, TelecomManager.PRESENTATION_ALLOWED)
        active?.let { endActive() }
        active = c
        c.setActive()
        return c
    }

    override fun onCreateOutgoingConnectionFailed(
        account: PhoneAccountHandle?,
        request: ConnectionRequest?,
    ) {
        SticksCallBridge.notifyFailed()
    }
}
