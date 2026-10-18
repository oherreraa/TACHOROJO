package pe.tachorojo.app;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.core.content.FileProvider;
import androidx.webkit.WebViewAssetLoader;

import java.io.File;

public class MainActivity extends Activity {
    private static final int REQ_FILE = 1;
    private WebView web;
    private ValueCallback<Uri[]> chooser;
    private Uri cameraUri;

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        // La app web se sirve desde assets/ bajo https://appassets.androidplatform.net/ (origen seguro, necesario para fetch y service worker).
        final WebViewAssetLoader loader = new WebViewAssetLoader.Builder()
                .addPathHandler("/", new WebViewAssetLoader.AssetsPathHandler(this)).build();
        web = new WebView(this);
        setContentView(web);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(false);
        web.setWebViewClient(new WebViewClient() {
            @Override public WebResourceResponse shouldInterceptRequest(WebView v, WebResourceRequest r) {
                return loader.shouldInterceptRequest(r.getUrl());
            }
        });
        web.setWebChromeClient(new WebChromeClient() {
            @Override public boolean onShowFileChooser(WebView v, ValueCallback<Uri[]> cb, FileChooserParams p) {
                if (chooser != null) chooser.onReceiveValue(null);
                chooser = cb;
                try {
                    File f = File.createTempFile("residuo", ".jpg", getCacheDir());
                    cameraUri = FileProvider.getUriForFile(MainActivity.this, "pe.tachorojo.app.fileprovider", f);
                } catch (Exception e) { cameraUri = null; }
                Intent pick = new Intent(Intent.ACTION_GET_CONTENT).addCategory(Intent.CATEGORY_OPENABLE).setType("image/*");
                Intent main;
                if (p.isCaptureEnabled() && cameraUri != null) {
                    main = new Intent(MediaStore.ACTION_IMAGE_CAPTURE).putExtra(MediaStore.EXTRA_OUTPUT, cameraUri)
                            .addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
                } else {
                    main = Intent.createChooser(pick, "Elegir foto");
                    if (cameraUri != null) main.putExtra(Intent.EXTRA_INITIAL_INTENTS, new Intent[]{
                            new Intent(MediaStore.ACTION_IMAGE_CAPTURE).putExtra(MediaStore.EXTRA_OUTPUT, cameraUri)
                                    .addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)});
                }
                try { startActivityForResult(main, REQ_FILE); } catch (Exception e) { chooser.onReceiveValue(null); chooser = null; return false; }
                return true;
            }
        });
        web.loadUrl("https://appassets.androidplatform.net/index.html");
    }

    @Override
    protected void onActivityResult(int req, int res, Intent data) {
        if (req != REQ_FILE || chooser == null) { super.onActivityResult(req, res, data); return; }
        Uri[] out = null;
        if (res == RESULT_OK) {
            if (data != null && data.getData() != null) out = new Uri[]{data.getData()};
            else if (cameraUri != null) out = new Uri[]{cameraUri};
        }
        chooser.onReceiveValue(out);
        chooser = null;
    }

    @Override
    public void onBackPressed() {
        if (web.canGoBack()) web.goBack(); else super.onBackPressed();
    }
}
