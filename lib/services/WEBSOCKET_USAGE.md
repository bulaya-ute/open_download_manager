# WebSocket Usage Guide

## Overview
The Gateway class now supports WebSocket connections for real-time bidirectional communication between the Flutter app and the Python server.

## Features
✅ **Automatic Connection**: Connects during `Gateway.init()`  
✅ **Auto-Reconnection**: Automatically reconnects if connection is lost  
✅ **Message Callbacks**: Register handlers for incoming messages  
✅ **Status Callbacks**: Track connection status changes  
✅ **Send Messages**: Send messages to the server  
✅ **Graceful Disconnect**: Clean disconnection with reconnection prevention  

## Basic Usage

### 1. Setting Up Message Handler

```dart
// Set up the message handler before calling Gateway.init()
Gateway.onWebSocketMessage = (message) {
  print("Received WebSocket message: $message");
  
  // Parse and handle the message
  try {
    final data = jsonDecode(message);
    
    // Handle different message types
    switch (data['type']) {
      case 'download_progress':
        _handleDownloadProgress(data);
        break;
      case 'download_complete':
        _handleDownloadComplete(data);
        break;
      case 'download_error':
        _handleDownloadError(data);
        break;
      default:
        print("Unknown message type: ${data['type']}");
    }
  } catch (e) {
    print("Error parsing WebSocket message: $e");
  }
};

// Set up connection status handler (optional)
Gateway.onWebSocketStatusChange = (isConnected) {
  print("WebSocket connection status: ${isConnected ? 'Connected' : 'Disconnected'}");
  
  // Update UI or handle connection status
  if (isConnected) {
    // Connection established
  } else {
    // Connection lost
  }
};

// Initialize Gateway (this will connect WebSocket automatically)
await Gateway.init();
```

### 2. Sending Messages to Server

```dart
// Send a text message
Gateway.sendWebSocketMessage("Hello from Flutter!");

// Send JSON data
final data = {
  'action': 'pause_download',
  'download_id': '12345',
};
Gateway.sendWebSocketMessage(jsonEncode(data));
```

### 3. Checking Connection Status

```dart
if (Gateway.isWebSocketConnected) {
  print("WebSocket is connected");
} else {
  print("WebSocket is not connected");
}
```

### 4. Manual Connection Control

```dart
// Manually connect (only if you disconnected manually)
await Gateway.connectWebSocket();

// Disconnect and prevent auto-reconnection
await Gateway.disconnectWebSocket();
```

## Complete Example: Download Progress Updates

```dart
class DownloadManager {
  void setupWebSocket() {
    Gateway.onWebSocketMessage = (message) {
      try {
        final data = jsonDecode(message);
        
        switch (data['type']) {
          case 'download_progress':
            _updateDownloadProgress(
              downloadId: data['download_id'],
              progress: data['progress'],
              speed: data['speed'],
            );
            break;
            
          case 'download_complete':
            _markDownloadComplete(
              downloadId: data['download_id'],
              filePath: data['file_path'],
            );
            break;
            
          case 'download_error':
            _handleDownloadError(
              downloadId: data['download_id'],
              error: data['error_message'],
            );
            break;
        }
      } catch (e) {
        print("Error handling WebSocket message: $e");
      }
    };
    
    Gateway.onWebSocketStatusChange = (isConnected) {
      if (!isConnected) {
        // Show "Disconnected" indicator in UI
        _showConnectionLostIndicator();
      } else {
        // Hide indicator
        _hideConnectionLostIndicator();
      }
    };
  }
  
  void _updateDownloadProgress({
    required String downloadId,
    required double progress,
    required int speed,
  }) {
    // Update your download state
    setState(() {
      final download = downloads.firstWhere((d) => d.id == downloadId);
      download.progress = progress;
      download.speed = speed;
    });
  }
  
  void _markDownloadComplete({
    required String downloadId,
    required String filePath,
  }) {
    setState(() {
      final download = downloads.firstWhere((d) => d.id == downloadId);
      download.status = DownloadStatus.completed;
      download.filePath = filePath;
    });
  }
  
  void _handleDownloadError({
    required String downloadId,
    required String error,
  }) {
    setState(() {
      final download = downloads.firstWhere((d) => d.id == downloadId);
      download.status = DownloadStatus.error;
      download.errorMessage = error;
    });
  }
}
```

## Server-Side: Sending Messages to Clients

In your Python server (`daemon_main.py`), you can broadcast messages to all connected clients:

```python
import json
from lib.backend.daemon.daemon_main import broadcast_message

# Send a message to all connected clients
async def notify_download_progress(download_id: str, progress: float, speed: int):
    message = json.dumps({
        'type': 'download_progress',
        'download_id': download_id,
        'progress': progress,
        'speed': speed,
    })
    await broadcast_message(message)

# In your download manager, call this function:
await notify_download_progress('12345', 0.75, 1024000)
```

## Connection Details

- **WebSocket URL**: `ws://<host>:<port>/ws`
- **Default**: `ws://localhost:8080/ws`
- **Auto-Reconnect Delay**: 5 seconds
- **Connection Method**: Automatic on `Gateway.init()`

## Troubleshooting

### WebSocket Not Connecting

1. Ensure the server is running: `await Gateway.isServerRunning`
2. Check server logs for WebSocket errors
3. Verify the host and port in `Config.serverHost` and `Config.serverPort`
4. Check firewall settings

### Messages Not Received

1. Check if WebSocket is connected: `Gateway.isWebSocketConnected`
2. Verify the message handler is set: `Gateway.onWebSocketMessage != null`
3. Check server-side broadcasting logic
4. Enable debug prints in Gateway to see received messages

### Connection Keeps Dropping

1. Check network stability
2. Review server logs for errors
3. Increase timeout if needed
4. Check if server is properly handling WebSocket connections

## Best Practices

1. **Set handlers before init**: Set `onWebSocketMessage` and `onWebSocketStatusChange` before calling `Gateway.init()`
2. **Handle connection loss gracefully**: Use `onWebSocketStatusChange` to update UI when connection is lost
3. **Parse messages safely**: Always use try-catch when parsing JSON messages
4. **Don't block handlers**: Keep message handlers fast and non-blocking
5. **Close when done**: Call `disconnectWebSocket()` when shutting down the app

## Dependencies

The WebSocket functionality uses Dart's built-in `dart:io` WebSocket support. No additional dependencies are required for the Flutter side.

For the Python server, FastAPI's built-in WebSocket support is used (already included in FastAPI).
