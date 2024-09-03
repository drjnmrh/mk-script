package com.stoned_fox.smile;

import android.view.Surface;
import android.content.Context;

public final class SmileCore {
    public static native void onSurfaceCreated();

    public static native void onSurfaceDestroyed();

    public static native void resizeSurface(int w, int h);

    public static native void setUp(Context ctx);

    public static native void tearDown();

    public static native void onDrawFrame();

}

