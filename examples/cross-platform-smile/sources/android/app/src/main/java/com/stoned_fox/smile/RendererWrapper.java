package com.stoned_fox.smile;

import android.opengl.GLES30;
import android.opengl.GLES32;
import android.opengl.GLSurfaceView;
import android.util.Log;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public class RendererWrapper implements GLSurfaceView.Renderer {
    @Override
    public void onSurfaceCreated(GL10 gl10, EGLConfig eglConfig) {
        SmileCore.onSurfaceCreated();

        int[] vers = new int[2];
        gl10.glGetIntegerv(GLES30.GL_MAJOR_VERSION, vers, 0);
        gl10.glGetIntegerv(GLES30.GL_MINOR_VERSION, vers, 1);
        Log.d("Smile", String.format("SmileSurfaceView: v%d.%d", vers[0], vers[1]));
    }

    @Override
    public void onSurfaceChanged(GL10 gl10, int width, int height) {
        SmileCore.resizeSurface(width, height);
        gl10.glViewport(0, 0, width, height);
    }

    @Override
    public void onDrawFrame(GL10 gl10) {
        SmileCore.onDrawFrame();
    }
}

