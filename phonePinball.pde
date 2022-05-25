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

//  constants
int NUM_NOTES = 5;
final int NUM_BUMPERS = 10;

//  scoring
int score = 0;
boolean gameOver = false;

//  sound
String[] noteFileNames = new String[NUM_NOTES];
MediaPlayer[] noteMPs = new MediaPlayer[NUM_BUMPERS];
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

boolean hasChanged = false;
color backCol;
color typeCol;
color ballCol;
color obstacleCol;

Circle ball;
Obstacle obstacle1;
Obstacle[] obstacles = new Obstacle[NUM_BUMPERS];

int timeTouchBegan;

boolean mouseIsDown = false;

void setup() {
    println("Setting up; displayDensity: " + displayDensity);
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
        if (i%2 == 0) {
            obstacles[i] = new GoodObstacle(new PVector(x, y), 20, 20);
        } else {
            obstacles[i] = new BadObstacle(new PVector(x, y), 20, 20);
        }
        // obstacles[i].setColor(color(175, 100, 100));
        // obstacles[i].setSecondaryColor(color(200, 100, 100));
        obstacles[i].setNote(noteMPs[i % NUM_NOTES]);
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
    obstacle1 = new NeutralObstacle(new PVector(200, 500), 15, 15);

    hasRunSetup = true;
    timeTouchBegan = millis();
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
        if (!mouseIsDown || millis() - timeTouchBegan < 1000) {
            ball.applyForce(sensorForce);
        }
        hasChanged = false;
    }

    if (mouseIsDown && millis() - timeTouchBegan > 1000) {
        if (gameOver) {
            // println("We're resetting, mouse is Down");
            timeTouchBegan = millis(); // reset every second
            float newHue = random(360);
            ballCol = color(newHue, 100, 100);
            ball.setColor(ballCol);
            ball.setVelocity(0, 0);
            // diameter = random(100, 300);
            ball.pos.set(mouseX, mouseY);
            snd.seekTo(0);
            snd.start();
            resetGame();
        }
    } else {
        if (!gameOver) {
            updateBallAndObstacles();
        }
    }

    //  neutral obstacle plus the pointer to the ball
    strokeWeight(1);
    obstacle1.draw();
    PVector normal = ball.getNormalizedNormal(obstacle1);
    PVector normalCopy = normal.copy();
    normalCopy.mult(200);
    PVector endOfLine = obstacle1.pos.copy();
    endOfLine.add(normalCopy);
    fill(color(25, 100, 100));
    stroke(color(25, 100, 100));
    strokeWeight(2);
    line(obstacle1.pos.x, obstacle1.pos.y, endOfLine.x, endOfLine.y);
    circle(endOfLine.x, endOfLine.y, 10);
    for (int i = 0; i < NUM_BUMPERS; i++) {
        obstacles[i].draw();
    }
    ball.draw();
    if (mouseIsDown) {
        strokeWeight(4);
        PVector reflection = ball.getReflectionVector(normal);
        reflection.normalize();
        reflection.mult(50);
        reflection.add(ball.pos);
        stroke(color(100, 0, 100));
        line(ball.pos.x, ball.pos.y, reflection.x, reflection.y);
    }
    fill(0, 0, 100); // white
    String endText = gameOver ? "!!!!!" : ".";
    text("Score: " + score + endText, 10, displayHeight - 30 * displayDensity);

}

void updateBallAndObstacles() {
    ball.bounceDisplayBoundaries();
    if (ball.doesCollideWithObstacle(obstacle1)) {
        ball.bounceAgainstCircleObstacle(obstacle1);
    }
    for (int i = 0; i < NUM_BUMPERS; i++) {
        boolean shouldReact = true;
        if (ball.doesCollideWithObstacle(obstacles[i])) {
            if (obstacles[i].getType() == ObstacleType.GOOD) {
                if(obstacles[i].getIsHit()) {
                    shouldReact = false;
                } else {
                    println("Hit good one... chcking");
                    score += 5;
                }
            } else if (obstacles[i].getType() == ObstacleType.BAD) {
                score -= 5;
            }
            ball.bounceAgainstCircleObstacle(obstacles[i]);
            if (shouldReact) {
                obstacles[i].wiggle();
                if (obstacles[i].getType() == ObstacleType.GOOD) {
                    if (didHitAllGoodObstacles()) {
                        println("all done");
                        gameOver = true;
                    } else {
                        println("NOt all done");
                    }
                }
                if (mediaPreparedMap.containsKey(obstacles[i].getNote())) {
                    if (mediaPreparedMap.get(obstacles[i].getNote())) {
                        obstacles[i].playNote();
                    }
                }
            }
        }
    }
    ball.updatePos();
}

boolean didHitAllGoodObstacles() {
    for (Obstacle o : obstacles) {
        if (o.getType() == ObstacleType.GOOD && !o.getIsHit()) {
            return false;
        }
    }
    return true;
}

void resetGame() {
    score = 0;
    for (Obstacle o : obstacles) {
        if (o.getType() == ObstacleType.GOOD) {
            o.reset();
        }
    }
    gameOver = false;
}

void mousePressed() {
    mouseIsDown = true;
    timeTouchBegan = millis();
}

void mouseReleased() {
    mouseIsDown = false;
}

void setUpAllMediaPlayers() {
    for (int i = 0; i < NUM_BUMPERS; i++) {
        try {
            noteMPs[i] = new MediaPlayer();
            fd = context.getAssets().openFd(noteFileNames[i % NUM_NOTES]);
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
    for (int i = 0; i < NUM_BUMPERS; i++) {
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
