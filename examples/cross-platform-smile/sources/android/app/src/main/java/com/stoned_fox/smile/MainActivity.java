package com.stoned_fox.smile;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.view.WindowManager;


public class MainActivity extends AppCompatActivity {

    // Used to load the 'smile' library on application startup.
    static {
        System.loadLibrary("smile");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    protected void onStart() {
        super.onStart();
        SmileCore.setUp(getApplicationContext());
    }

    protected void onStop() {
        super.onStop();
        SmileCore.tearDown();
    }
}
