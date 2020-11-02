

void setup(){
  //size(1920,1080,P2D);
  fullScreen(P2D);
  textFont(createFont("Consolas",64));
  initUI();
  initElements();
  initEnv();
}


void draw(){
  background(0);
  displayUI();
  if(isSimulating){
    runSim();
    displaySim();
  }
}


void mousePressed(){
  parseEvent(eventName());
}

void keyPressed(){
  typeToSelected(key);
}
