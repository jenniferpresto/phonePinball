public static enum ObstacleType {
    NEUTRAL,
    GOOD,
    BAD,
    NONE
};

abstract class Obstacle {
    PVector pos;
    PVector wigglePos;
    float w, h;
    color col;
    color col2;
    color wiggleCol;
    color wiggleCol2;
    float rad;
    MediaPlayer note;
    boolean isHit = false;

    ObstacleType type;
    
    //  wiggling
    int timeWiggleStarted;
    boolean isWiggling;
    int wiggleDuration = 500; // in millis

    Obstacle(PVector pos, float w, float h) {
        this.pos = pos;
        this.wigglePos = pos.copy();
        this.w = w;
        this.h = h;
        this.rad = 35 * displayDensity;
        this.type = ObstacleType.NONE;
        col = color(247, 66, 97); // bluish purple
        col2 = color(231, 61, 88); // lighter, grayer blue
        wiggleCol = color(8, 66, 97); // orange red
        wiggleCol2 = color(21, 61, 88); // orange beige
    }

    ObstacleType getType() { return this.type; }

    boolean getIsHit() { return this.isHit; }
    void reset() {
        this.isHit = false;
    }
    
    void setColor(color c) {
        println("set color");
        this.col = c;
    }
    
    void setSecondaryColor(color c) {
        this.col2 = c;
    }

    void setWiggleColor(color c) {
        this.wiggleCol = c;
    }

    void setSecondaryWiggleColor(color c) {
        this.wiggleCol2 = c;
    }
    
    MediaPlayer getNote() { return this.note; }
    void setNote(MediaPlayer note) {
        this.note = note;
        println("Set note to " + this.note);
    }
    
    void setRadius(float r) { this.rad = r; }

    void wiggle() {
        isWiggling = true;
        timeWiggleStarted = millis();
    }
    
    void updateWigglePos() {
        float angle = random(TWO_PI);
        float dist = random(7.0);
        float x = cos(angle);
        float y = sin(angle);
        wigglePos.set(x, y);
        wigglePos.mult(dist);
        wigglePos.add(pos);
    }

    void draw() {
        PVector displayPos;
        if (isWiggling) {
            updateWigglePos();
            displayPos = wigglePos;
            if (millis() - timeWiggleStarted > wiggleDuration) {
                isWiggling = false;
            }
        } else {
            displayPos = pos;
        }
        if (isWiggling) {
            fill(this.wiggleCol);
        } else {
            fill(this.col);
        }
        circle(displayPos.x, displayPos.y, rad);
        if (isWiggling) {
            fill(this.wiggleCol2);
        } else {
            fill(col2);
        }
        rect(displayPos.x, displayPos.y,  w * displayDensity, h * displayDensity);
        fill(0);
        circle(displayPos.x, displayPos.y, 10 * displayDensity);
    }
    
    void playNote() {
        note.seekTo(0);
        note.start();
    }
}

class NeutralObstacle extends Obstacle {
    NeutralObstacle(PVector pos, float w, float h) {
        super(pos, w, h);
        this.col = color(0, 0, 60);
        this.col2 = color(0, 0, 85);
        this.rad = 25 * displayDensity;
        this.type = ObstacleType.NEUTRAL;
    }
}

class GoodObstacle extends Obstacle {
    GoodObstacle(PVector pos, float w, float h) {
        super(pos, w, h);
        this.col = color(127, 76, 70); // green
        this.col2 = color(127, 76, 90); // brighter green
        this.type = ObstacleType.GOOD;
    }

    @Override
    void reset() {
        super.reset();
        this.col = color(127, 76, 70); // green
        this.col2 = color(127, 76, 90); // brighter green
    }

    @Override
    void wiggle() {
        super.wiggle();
        isHit = true;
        this.col = color(0, 0, 66); // gray
        this.col2 = color(0, 0, 50); // darker gray
    }
}

class BadObstacle extends Obstacle {
    BadObstacle(PVector pos, float w, float h) {
        super(pos, w, h);
        this.type = ObstacleType.BAD;
    }
}