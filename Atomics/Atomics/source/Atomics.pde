

void setup(){ //Code here runs at program startup.
  fullScreen(P2D); //Makes the GUI be the size of the monitor.
  textFont(createFont("Consolas",64)); //Sets the default font of processing to be "Consolas".
  // - initiates programming elements.
  initUI();
  initElements();
  initEnv();
}


void draw(){
  background(0); //Sets the background black.
  displayUI(); //Draws the UIComponents which are visible.
  if(isSimulating){
    runSim();
    displaySim();
  }
}


void mousePressed(){
  parseEvent(eventName()); //Parses UI events based on the mouse being pressed and it's location.
}

void keyPressed(){
  typeToSelected(key); //Parses UI events from keypresses.
  parseTextEvent(textEvent(keyCode));
}
