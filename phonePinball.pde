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
//import android.media.MediaPlayer;
//import android.content.res.Resources;
//import android.content.res.AssetFileDescriptor;
//import android.content.res.AssetManager;

Context context;
SensorManager manager;
Sensor sensor;
//MediaPlayer mp;
//AssetFileDescriptor fd;
AccelerometerListener listener;

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
SoundFile[] notes = new SoundFile[5];

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
    
    //fd = context.getApplicationContext().getAssets().openFd("short.mp3");
    //mp = MediaPlayer.create(context, android.R.sound_file_1);
    //mp.setDataSource(fd.getFileDescriptor(), fd.getStartOffset(), fd.getLength());
    // audioFile = new SoundFile(this, "nice-work.wav");
    notes[0] = new SoundFile(this, "c-sharp.wav");
    notes[1] = new SoundFile(this, "d-sharp.wav");
    notes[2] = new SoundFile(this, "f-sharp.wav");
    notes[3] = new SoundFile(this, "g-sharp.wav");
    notes[4] = new SoundFile(this, "a-sharp.wav");
    
    for (int i = 0; i < NUM_BUMPERS; i++) {
        float x = random(100, displayWidth - 100);
        float y = (((displayHeight - 300) / NUM_BUMPERS) * i) + 150;
        obstacles[i] = new Obstacle(new PVector(x, y), 75, 75);
        obstacles[i].setNote(notes[i % 5]);
        // obstacles[i].setColor(color(175, 100, 100));
        // obstacles[i].setSecondaryColor(color(200, 100, 100));
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
}

void mouseReleased() {
    mouseIsDown = false;
}

public void onResume() {
    println("onResume");
    super.onResume();
    if (manager != null) {
        manager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_GAME);
    }
}

public void onPause() {
    println("onPause");
    super.onPause();
    if (manager != null) {
        manager.unregisterListener(listener);
    }
    for (int i = 0; i < 5; i++) {
        notes[i].stop();
    }
}

@Override
public void onCreate(Bundle savedInstanceState) {
    println("on create called!");
    println(savedInstanceState);
    super.onCreate(savedInstanceState);
}

@Override
public void onDestroy() {
    println("On destroy");
    // audioFile.stop();
    super.onDestroy();
    for (int i = 0; i < 5; i++) {
        notes[i].stop();
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
