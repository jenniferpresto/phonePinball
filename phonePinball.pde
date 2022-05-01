/**
Some nice references:
http://bocilmania.com/2018/04/21/how-to-get-reflection-vector/
For more intricate animations:
https://processing.org/examples/circlecollision.html
*/

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorManager;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.os.Bundle;

import processing.sound.*;
import android.media.MediaPlayer;
import android.content.res.Resources;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.app.Activity;
import android.media.MediaPlayer.OnPreparedListener;

import java.util.Map;

Context context;
SensorManager manager;
Sensor sensor;
AccelerometerListener listener;

//  sound
String[] noteFileNames = new String[5];
MediaPlayer[] noteMPs = new MediaPlayer[5];
HashMap<MediaPlayer, Boolean> mediaPreparedMap;

MediaPlayer snd = new MediaPlayer();
AssetFileDescriptor fd;
Activity act;

Boolean hasRunSetup = false;

float ax, ay, az;

PVector sensorForce;
PVector circlePos;
PVector circleVel;
float circleX, circleY;
float velX, velY;
float accX, accY;
float maxVel = 35;
// float bouncePct = -0.55;
// float friction = 0.997;
// float diameter = 150;

boolean hasChanged = false;
color backCol;
color typeCol;
color ballCol;
color obstacleCol;

final int NUM_BUMPERS = 10;
Circle ball;
Obstacle obstacle1;
Obstacle[] obstacles = new Obstacle[NUM_BUMPERS];



boolean mouseIsDown = false;

void setup() {
    println("setup");
    fullScreen();
    colorMode(HSB, 360, 100, 100);
    ellipseMode(RADIUS);
    rectMode(CENTER);
    context = getActivity();
    manager = (SensorManager)context.getSystemService(Context.SENSOR_SERVICE);
    sensor = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
    listener = new AccelerometerListener();
    manager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_GAME);
    textFont(createFont("SansSerif", 20 * displayDensity));

    noteFileNames[0] = "c-sharp.wav";
    noteFileNames[1] = "d-sharp.wav";
    noteFileNames[2] = "f-sharp.wav";
    noteFileNames[3] = "g-sharp.wav";
    noteFileNames[4] = "a-sharp.wav";

    mediaPreparedMap = new HashMap<MediaPlayer, Boolean>();

    setUpAllMediaPlayers();

    try {
        fd = context.getAssets().openFd("nice-work.wav");
        snd.setDataSource(fd.getFileDescriptor(), fd.getStartOffset(), fd.getLength());
        snd.prepare();
       //snd.setOnPreparedListener(new onPreparedListener() {
       //    @Override
       //    public void onPrepared(MediaPlayer mp) {
       //        println("Media player is prepared");
       //        mediaPreparedMap.put(mp, true);
       //    };
       //});
    }
    catch (IllegalArgumentException e) {
        e.printStackTrace();
    }
    catch (IllegalStateException e) {
        e.printStackTrace();
    }
    catch (IOException e) {
        e.printStackTrace();
    }
    
    for (int i = 0; i < NUM_BUMPERS; i++) {
        float x = random(100, displayWidth - 100);
        float y = (((displayHeight - 300) / NUM_BUMPERS) * i) + 150;
        obstacles[i] = new Obstacle(new PVector(x, y), 75, 75);
        // obstacles[i].setColor(color(175, 100, 100));
        // obstacles[i].setSecondaryColor(color(200, 100, 100));
        obstacles[i].setNote(noteMPs[i % 5]);
    }
    
    circlePos = new PVector(displayWidth / 2, displayHeight / 2);
    circleVel = new PVector();
    sensorForce = new PVector();
    circleX = displayWidth / 2;
    circleY = displayHeight / 2;
    
    backCol = color(0, 0, 20);
    typeCol = color(216, 100, 100);
    ballCol = color(30, 100, 100);
    obstacleCol = color(131, 84, 100);
    
    ball = new Circle();
    ball.setColor(ballCol);
    obstacle1 = new Obstacle(new PVector(200, 500), 50, 70);
    obstacle1.setColor(color(255, 100, 100));

    hasRunSetup = true;
}

void draw() {
    background(backCol);
    fill(typeCol);
    rectMode(CORNER);
    text("X: " + ax + 
        "\nY: " + ay +
        "\nZ: " + az +
        "\nxVel: " + ball.vel.x +
        "\nyVel: " + ball.vel.y +
        "\npos: " + ball.pos.x + "," + ball.pos.y,
        50, 50);
    rectMode(CENTER);
    if (hasChanged) {
        sensorForce.set( -ax * 0.075, ay * 0.075);
        if (!mouseIsDown) {
            ball.applyForce(sensorForce);
        }
        hasChanged = false;
    }
    if (ball.doesCollideWithObstacle(obstacle1)) {
        obstacle1.setColor(color(0, 100, 100));
    }
    else {
        obstacle1.setColor(obstacleCol);
    }
    if (mouseIsDown) {
        ball.pos.set(mouseX, mouseY);
    } else {
        ball.bounceDisplayBoundaries();
        if (ball.doesCollideWithObstacle(obstacle1)) {
            ball.bounceAgainstCircleObstacle(obstacle1);
        }
        for (int i = 0; i < NUM_BUMPERS; i++) {
            if (ball.doesCollideWithObstacle(obstacles[i])) {
                ball.bounceAgainstCircleObstacle(obstacles[i]);
                obstacles[i].wiggle();
                println("Trying to bump: " + mediaPreparedMap.size());
                for(MediaPlayer mp : mediaPreparedMap.keySet()) {
                    println("MP: " + mp);
                    println("Value: " + mediaPreparedMap.get(mp));
                    println("Obstacle value: " + obstacles[i].getNote());
                }

                
                if (mediaPreparedMap.containsKey(obstacles[i].getNote())) {
                    println("Contains key");
                    if (mediaPreparedMap.get(obstacles[i].getNote())) {
                        println("true");
                        obstacles[i].playNote();
                    } else {
                        println("false");
                    }
                }
            }
        }
        ball.updatePos();
    }
    strokeWeight(1);
    obstacle1.draw();
    for (int i = 0; i < NUM_BUMPERS; i++) {
        obstacles[i].draw();
    }
    ball.draw();
    PVector normal = ball.getNormalizedNormal(obstacle1);
    PVector normalCopy = normal.copy();
    normalCopy.mult(200);
    PVector endOfLine = obstacle1.pos.copy();
    endOfLine.add(normalCopy);
    fill(color(25, 100, 100));
    stroke(color(25, 100, 100));
    strokeWeight(8);
    line(obstacle1.pos.x, obstacle1.pos.y, endOfLine.x, endOfLine.y);
    circle(endOfLine.x, endOfLine.y, 10);
    if (mouseIsDown) {
    strokeWeight(4);
        PVector reflection = ball.getReflectionVector(normal);
        reflection.normalize();
        reflection.mult(50);
        reflection.add(ball.pos);
        stroke(color(100, 0, 100));
        line(ball.pos.x, ball.pos.y, reflection.x, reflection.y);
    }
}

void mousePressed() {
    mouseIsDown = true;
    float newHue = random(360);
    ballCol = color(newHue, 100, 100);
    ball.setColor(ballCol);
    ball.setVelocity(0, 0);
    // diameter = random(100, 300);
    ball.pos.set(mouseX, mouseY);
    // try {
    //   //if (!snd.isPlaying()) {
    //   //  println("Preparing");
    //   //  snd.prepare();
    //   //} else {
    //   //  println("Seeking to zero");
    //   //  snd.prepare();
    //   //  snd.seekTo(0);
    //   //}
    //     println("preparing when pressed");
    //     snd.prepare();

    // }
    // catch (IllegalArgumentException e) {
    //     e.printStackTrace();
    // }
    // catch (IllegalStateException e) {
    //     e.printStackTrace();
    // }
    // catch (IOException e) {
    //     e.printStackTrace();
    // }
    snd.seekTo(0);
    snd.start();
}

void mouseReleased() {
    mouseIsDown = false;
}

void setUpAllMediaPlayers() {
    for (int i = 0; i < 5; i++) {
        try {
            noteMPs[i] = new MediaPlayer();
            fd = context.getAssets().openFd(noteFileNames[i]);
            noteMPs[i].setDataSource(fd.getFileDescriptor(), fd.getStartOffset(), fd.getLength());
            noteMPs[i].setOnPreparedListener(new OnPreparedListener() {
              public void onPrepared(MediaPlayer mp) {
                if (mediaPreparedMap.containsKey(mp)) {
                    mediaPreparedMap.replace(mp, true);
                } else {
                    mediaPreparedMap.put(mp, true);
                }
              }
            });
            noteMPs[i].prepare();
        }
        catch (IllegalArgumentException e) {
            e.printStackTrace();
        }
        catch (IllegalStateException e) {
            e.printStackTrace();
        }
        catch (IOException e) {
            e.printStackTrace();
        }
    }    
}

@Override
public void onResume() {
    println("onResume");
    super.onResume();
    if (manager != null) {
        manager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_GAME);
    }
    if (hasRunSetup) {
        setUpAllMediaPlayers();
    }
}

@Override
public void onPause() {
    println("onPause");
    super.onPause();
    if (manager != null) {
        manager.unregisterListener(listener);
    }
    if (snd != null) {
        snd.release();
        snd = null;
    }
    for (int i = 0; i < 5; i++) {
        // if (notes[i] != null) {
        //     notes[i].stop();
        // }
        if (noteMPs[i] != null) {
            noteMPs[i].release();
            noteMPs[i] = null;
            mediaPreparedMap.replace(noteMPs[i], false);
        }
    }
}

@Override
public void onCreate(Bundle savedInstanceState) {
    println("onCreate");
    println(savedInstanceState);
    super.onCreate(savedInstanceState);
}

@Override
public void onStop() {
    println("onStop");
    super.onStop();
    if (snd != null) {
        snd.release();
        snd = null;
    }
    for (int i = 0; i < 5; i ++) {
        if (noteMPs[i] != null) {
            noteMPs[i].release();
            noteMPs[i] = null;
            mediaPreparedMap.replace(noteMPs[i], false);
        }
    }
}

@Override
public void onDestroy() {
    println("onDestroy");
    // audioFile.stop();
    super.onDestroy();
    if (snd != null) {
        snd.release();
        snd = null;
    }
    for (int i = 0; i < 5; i++) {
        // if (notes[i] != null) {
        //     notes[i].stop();
        // }
        if (noteMPs[i] != null) {
            noteMPs[i].release();
            noteMPs[i] = null;
            mediaPreparedMap.replace(noteMPs[i], false);
        }
    }
}

class AccelerometerListener implements SensorEventListener {
    public void onSensorChanged(SensorEvent event) {
        ax = event.values[0];
        ay = event.values[1];
        az = event.values[2];
        hasChanged = true;
    }
    
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
    }
}
