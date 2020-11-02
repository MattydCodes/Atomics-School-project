UIcomp[] UIComponents;
String typeable = "abcdefghijklmnopqrstuvwxyz.0123456789_-, ";

void initUI(){
  UIComponents = new UIcomp[3];
  UIComponents[0] = new Button("New Simulation",new PVector(800,300),240,60);
  UIComponents[0].setFontSize(30);
  UIComponents[0].setVisibility(true);
  UIComponents[1] = new Button("Load Simulation",new PVector(800,500),260,60);
  UIComponents[1].setFontSize(30);  
  UIComponents[1].setVisibility(true);
  UIComponents[2] = new Button("Exit",new PVector(880,700),80,60);
  UIComponents[2].setFontSize(30);  
  UIComponents[2].setVisibility(true);
}



void displayUI(){
  for(int i = 0; i < UIComponents.length; i++){
    UIComponents[i].display();
  }
}

void goToSim(){
 UIComponents[0].setVisibility(false);
 UIComponents[1].setVisibility(false);
 UIComponents[2].setVisibility(false);
 createTempMolecules();
 isSimulating = true;
}

String eventName(){
  for(int i = 0; i < UIComponents.length; i++){
    if(UIComponents[i].isPressed()){
      return UIComponents[i].id;
    }
  }
  return "";
}



void typeToSelected(char k){
  for(int i = 0; i < UIComponents.length; i++){
    if(UIComponents[i].isSelected() && isTypeable(str(k))){
      UIComponents[i].typeChar(str(k));
    }
    if(k == 8){
      UIComponents[i].backspace();
    }
  }
}


void parseEvent(String id){
  if(id.equals("New Simulation")){
    goToSim();
  }else if(id.equals("Exit")){
    exit();
  }else if(true){
  }
}



class UIcomp{ //Using inheritence allows us to use a single class type to interact with all UI elements.
  String id;
  PVector pos;
  int sizex;
  int sizey;
  int fontSize;
  boolean visible;  
  boolean selected;
  String contents;
  int charLimit;
  
  UIcomp(String id, PVector pos, int x, int y){
    this.id = id;
    this.pos = pos.copy();
    this.sizex = x;
    this.sizey = y;
    this.visible = false;   
    this.contents = "";
    this.selected = false;
    this.fontSize = 14;
    charLimit = int(sizex/14.0);
  }
  
  void display(){
  }
  
  boolean isPressed(){
    return false;
  }
  
  boolean isSelected(){
    return selected;
  }
  
  int getCharLimit(){
    return charLimit;
  }
  
  String getContents(){
    return contents;
  }
  
  void typeChar(String k){
    if(contents.length() < charLimit){
      contents = contents + k;
    }
  }
  
  void backspace(){
    if(contents.length() > 0){
      contents = contents.substring(0,contents.length()-1);
    }
  }
  
  void setVisibility(boolean state){
    visible = state;
  }
  
  void setFontSize(int size){
    fontSize = size;
  }
}


class Button extends UIcomp{
  
  Button(String id, PVector pos, int x, int y){
    super(id,pos,x,y);
  }
  
  void display(){
    if(visible){
      fill(50);
      stroke(200);
      rect(pos.x,pos.y,sizex,sizey);
      fill(255);
      textSize(fontSize);
      text(id,pos.x+2,pos.y+fontSize);
    }
  }
  
  boolean isPressed(){
    if((mouseX > pos.x && mouseY > pos.y) && (mouseX < pos.x+sizex && mouseY < pos.y+sizey) && visible){
      println("Clicked"+id);
      return true;
    }
    return false;
  }
}



class Textbox extends UIcomp{
  
  Textbox(String id, PVector pos, int x, int y){
    super(id,pos,x,y);
  }
 
  void display(){
    fill(50,50,50);
    stroke(200);
    rect(pos.x,pos.y,sizex,sizey);
    fill(255);
    textSize(fontSize);
    if(contents.equals("")){
      text(id,pos.x+2,pos.y+fontSize);
    }else{
      text(contents,pos.x+2,pos.y+fontSize);
    }
  } 
  
  boolean isPressed(){
    if((mouseX > pos.x && mouseY > pos.y) && (mouseX < pos.x+sizex && mouseY < pos.y+sizey) && visible){
      println("Clicked"+id);
      selected = true;
      return true;
    }
    selected = false;
    return false;
  }
  
  
  void setFontSize(int size){
    fontSize = size;
    charLimit = int(sizex/float(size))*2-1;
  }
}


boolean isTypeable(String k){
  for(int i = 0; i < typeable.length(); i++){
    if(typeable.substring(i,i+1).equals(k)){
      return true;
    }
  }
  return false;
}
