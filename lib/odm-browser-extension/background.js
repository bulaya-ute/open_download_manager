chrome.downloads.onCreated.addListener((downloadItem) => {
  const url = downloadItem.url;
  console.log("Intercepted download:", url);

  // Cancel the browser’s default download
  chrome.downloads.cancel(downloadItem.id, () => {
    // Send to ODM via native messaging
    sendToODM(url);
  });
});

function sendToODM(url) {
  chrome.runtime.sendNativeMessage(
    "com.odm.downloader", // This is your registered app name
    { command: "download", url: url },
    (response) => {
      console.log("ODM response:", response);
    }
  );
}
