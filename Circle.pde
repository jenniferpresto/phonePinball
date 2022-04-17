class Circle {
    PVector pos;
    PVector vel;
    float rad = 50;
    color col;
    float friction = 0.998f;
    float bouncePct = -0.55;
    float maxVel = 35;
    
    Circle() {
        pos = new PVector(displayWidth / 2, displayHeight / 2);
        println("Instantiate circle: " + pos);
        vel = new PVector(0, 0);
        rad = 50;
    }
    
    void setColor(color c) {
        col = c;
    }
    
    void setRadius(float r) {
        rad = r;
    }

    void setVelocity(float x, float y) {
        vel.set(x, y);
    }
    
    void draw() {
        fill(col);
        circle(pos.x, pos.y, rad);
        fill(color(87,100, 100));
        stroke(color(87, 100, 100));
        PVector velCopy = vel.copy();
        velCopy.mult(10);
        velCopy.add(pos);
        strokeWeight(4);
        line(pos.x, pos.y, velCopy.x, velCopy.y);
        strokeWeight(1);
    }
    
    void updatePos() {
        pos.add(vel);
    }
    
    void applyForce(PVector force) {
        // println("Force + " + force);
        vel.add(force);
        vel.mult(friction);
        if (vel.magSq() > maxVel * maxVel) {
            vel.normalize();
            vel.mult(maxVel);
        }
    }
    
    void bounceDisplayBoundaries() {
        if (vel.x > 0) {
            bounceToTheLeft(displayWidth);
        } else {
            bounceToTheRight(0);
        }
        if (vel.y > 0) {
            bounceUp(displayHeight);
        } else {
            bounceDown(0);
        }
        
        //  failsafe
        if (pos.x > displayWidth) {
            bounceToTheLeft(displayWidth);
        } else if (pos.x < 0) {
            bounceToTheRight(0);
        }
        if (pos.y > displayHeight) {
            bounceUp(displayHeight);
        } else if (pos.y < 0) {
            bounceDown(0);
        }
    }
    
    boolean doesCollideWithObstacle(Obstacle o) {
        //  circle collision
        PVector diff = PVector.sub(o.pos, pos);
        float distSq = diff.magSq();
        float collisionDist = o.rad + rad;
        float collisionDistSq = collisionDist * collisionDist;
        
        if (distSq < collisionDistSq) {
            o.setColor(color(360, 100, 100));
            return true;
        } else {
            o.setColor(color(180, 100, 100));
            return false;
        }
    }
    
    PVector getNormalizedNormal(Obstacle o) {
        PVector normal = PVector.sub(pos, o.pos);
        normal.normalize();
        return normal;
    }
    
    PVector getReflectionVector(Obstacle o) {
        PVector normal = getNormalizedNormal(o);
        return getReflectionVector(normal);
    }
    
    PVector getReflectionVector(PVector normal) {
        PVector velCopy = vel.copy();
        float scalar = 2 * vel.dot(normal);
        PVector normalCopy = normal.copy();
        normalCopy.mult(scalar);
        PVector reflection = velCopy.sub(normalCopy);
        return reflection;
    }
    
    void bounceAgainstCircleObstacle(Obstacle o) {
        PVector normal = getNormalizedNormal(o);
        PVector reflection  = getReflectionVector(normal);
        PVector normalCopy = normal.copy();
        PVector newPos = o.pos.copy().add(normalCopy.mult(o.rad + rad));
        pos.set(newPos);
        vel.set(reflection);
        vel.mult(1.1f); // juice the velocity a little bit
    }
    
    void bounceToTheLeft(float boundaryX) {
        float bounceX = boundaryX - rad;
        if (pos.x > bounceX) {
            bounceHorizontalVel(bounceX);
        }
    }
    
    void bounceToTheRight(float boundaryX) {
        float bounceX = boundaryX + rad;
        if (pos.x < bounceX) {
            bounceHorizontalVel(bounceX);
        }
    }
    
    void bounceUp(float boundaryY) {
        float bounceY = boundaryY - rad;
        if (pos.y > bounceY) {
            bounceVerticalVel(bounceY);
        }
    }
    
    void bounceDown(float boundaryY) {
        float bounceY = boundaryY + rad;
        if (pos.y < bounceY) {
            bounceVerticalVel(bounceY);
        }
    }
    
    void bounceHorizontalVel(float bounceX) {
        pos.set(bounceX, pos.y);
        float magSq = vel.magSq();
        if (magSq < 5.0) {
            vel.set(0, 0);
        } else {
            vel.set(vel.x * bouncePct, vel.y);
        }
    }
    
    void bounceVerticalVel(float bounceY) {
        pos.set(pos.x, bounceY);
        float magSq = vel.magSq();
        if (magSq < 5.0) {
            vel.set(0, 0);
        } else {
            vel.set(vel.x, vel.y * bouncePct);
        }
    }
}
