package com.stoned_fox.smile;

import android.content.Context;
import android.opengl.GLES30;
import android.opengl.GLSurfaceView;
import android.util.Log;
import android.view.SurfaceHolder;
import android.util.AttributeSet;

public class SmileSurfaceView extends GLSurfaceView {

    private final RendererWrapper mRenderer;

    public SmileSurfaceView(Context context) {
        super(context);
        setEGLContextClientVersion(3);
        mRenderer = new RendererWrapper();
        setRenderer(mRenderer);
    }

    public SmileSurfaceView(Context context, AttributeSet attr) {
        super(context, attr);
        setEGLContextClientVersion(3);
        mRenderer = new RendererWrapper();
        setRenderer(mRenderer);
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        SmileCore.onSurfaceDestroyed();
        super.surfaceDestroyed(holder);
    }
}

