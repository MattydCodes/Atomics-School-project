UIcomp[] UIComponents;
String typeable = "abcdefghijklmnopqrstuvwxyz.0123456789_-, ()+ABCDEFGHIJKLMNOPQRSTUVWXYZ[]";

void initUI(){
  UIComponents = new UIcomp[7];
  UIComponents[0] = new Button("New Simulation",new PVector(800,300),240,60);
  UIComponents[0].setFontSize(30);
  UIComponents[0].setVisibility(true);
  UIComponents[1] = new Button("Load Simulation [Coming Soon]",new PVector(800,500),260,60);
  UIComponents[1].setFontSize(30);  
  UIComponents[1].setVisibility(true);
  UIComponents[2] = new Button("Exit",new PVector(880,700),80,60);
  UIComponents[2].setFontSize(30);  
  UIComponents[2].setVisibility(true);
  initSimUI();
}



void initSimUI(){
  UIComponents[3] = new Textbox("Molecules",new PVector(1500,980),340,60);
  UIComponents[3].setFontSize(30);  
  UIComponents[3].setVisibility(false);  
  UIComponents[4] = new Button("Play",new PVector(1500,40),80,40);
  UIComponents[4].setFontSize(30);
  UIComponents[4].setVisibility(false);
  UIComponents[5] = new Button("Stop",new PVector(1610,40),80,40);
  UIComponents[5].setFontSize(30);
  UIComponents[5].setVisibility(false);
  UIComponents[6] = new Button("Reset",new PVector(1720,40),90,40);
  UIComponents[6].setFontSize(30);
  UIComponents[6].setVisibility(false);
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
  UIComponents[3].setVisibility(true); 
  UIComponents[4].setVisibility(true);
  UIComponents[5].setVisibility(true);
  UIComponents[6].setVisibility(true);
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

String[] textEvent(int k){
  for(int i = 0; i < UIComponents.length; i++){
    if(k == 10 && UIComponents[i].isSelected()){
      String temp = UIComponents[i].getContents();
      UIComponents[i].contents = "";
      return new String[]{UIComponents[i].id,temp};
    }
  } 
  return new String[]{"",""};
}



void typeToSelected(char k){
  for(int i = 0; i < UIComponents.length; i++){
    if(UIComponents[i].isSelected() && isTypeable(str(k))){
      UIComponents[i].typeChar(str(k));
    }
    if(k == 8 && UIComponents[i].isSelected()){
      UIComponents[i].backspace();
    }
  }
}


void parseEvent(String id){
  if(id.equals("New Simulation")){
    goToSim();
  }else if(id.equals("Exit")){
    exit();
  }else if(id.equals("Play")){
    running = true;
  }else if(id.equals("Stop")){
    running = false;
  }else if(id.equals("Reset")){
    running = false;
    Molecules = new ArrayList<Molecule>();
  }
}

void parseTextEvent(String[] data){  //Molecule format:   symbol/name(amount) + symbol/name(amount) +... ect , amount of molecule to place into container.
  if(data[0].equals("Molecules")){    
    try{
      String[] temp = data[1].split(",");
    
      int amount = int(temp[1]);
      
      if(amount+Molecules.size() > 200){
        println("Too many molecules");
      }else{
        
        println(temp[0]);
        temp[0] = temp[0].replaceAll("\\)","");
        
        String[] elements = temp[0].split("\\+");
        
        ArrayList<Atom> Atoms = new ArrayList<Atom>();
        
        for(int i = 0; i < elements.length; i++){
          String[] elementData = elements[i].split("\\(");
          
          String name = elementData[0];
          
          int index = findElementSymbol(name);
          
          if(index == -1){
            index = findElementName(name);
          }
          
          int quantity = int(elementData[1]);
          
          for(int j = 0; j < quantity; j++){
            Atoms.add(new Atom(index+2));
          }
        }
        
        
        for(int i = 0; i < amount; i++){
          Atom[] atomsArray = new Atom[Atoms.size()];
          for(int j = 0; j < Atoms.size(); j++){
            atomsArray[j] = new Atom(Atoms.get(j).getNumber());
          }
          Molecules.add(new Molecule(new PVector(random(1000),random(1000)),randomVec(),atomsArray));
        }
        
        for(int i = 0; i < 5; i++){
          collideMolecules(false);
          for(int j = 0; j < Molecules.size(); j++){
            Molecules.get(j).collideContainer();
          }
        }
      }
    }catch(Exception e){
      println(e);
    }
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
    if(visible){
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
