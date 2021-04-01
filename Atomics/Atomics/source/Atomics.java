import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Atomics extends PApplet {



public void setup(){ //Code here runs at program startup.
   //Makes the GUI be the size of the monitor.
  textFont(createFont("Consolas",64)); //Sets the default font of processing to be "Consolas".
  // - initiates programming elements.
  initUI();
  initElements();
  initEnv();
}


public void draw(){
  background(0); //Sets the background black.
  displayUI(); //Draws the UIComponents which are visible.
  if(isSimulating){
    runSim();
    displaySim();
  }
}


public void mousePressed(){
  parseEvent(eventName()); //Parses UI events based on the mouse being pressed and it's location.
}

public void keyPressed(){
  typeToSelected(key); //Parses UI events from keypresses.
  parseTextEvent(textEvent(keyCode));
}
//Molecules will contain an array of Atoms.
//Each Molecule will start off with just 1 atom unless speicified otherwise.


//Molecules will be represented with slightly bigger circles based on how many atoms there are in the molecule. So that the area is equal to the total of all the atoms area.


//In order to optimise the collision process from being O(n^2), I will create a "cell" map of the container and place each Molecule into the correct cell, it will then only need to check for collisions with it's neighbouring cells.

PGraphics moleculeRender;

public void updateMolecules(){ // Runs the update() method on each molecule in the Molecules ArrayList.
  for(int i = 0; i < Molecules.size(); i++){
    Molecules.get(i).update(); 
  }
}

public void displayMolecules(){ //Runs the display() method on each molecule in the Molecules ArrayList.
  for(int i = 0; i < Molecules.size(); i++){
    Molecules.get(i).display();
  }
}

public void collideMolecules(boolean react){ //Collides the Molecules, with the parameter "react" being used to tell the program if reactions should take place or not.
  
  int gridSize = 8;
  
  ArrayList<Molecule>[][] cellMap = new ArrayList[gridSize][gridSize];
  
  for(int x = 0; x < gridSize; x++){ //Initialises each index within the cellMap with an empty ArrayList of type Molecule.
    for(int y = 0; y < gridSize; y++){
      cellMap[x][y] = new ArrayList<Molecule>();
    }
  }
  
  for(int i = 0; i < Molecules.size(); i++){ //Places each molecule within the Molecules ArrayList into the cellMap based on the integer version of its x and y values (position).
    Molecule current = Molecules.get(i);
    current.reacted = false;
    int x = PApplet.parseInt(current.pos.x/(1000/gridSize));
    int y = PApplet.parseInt(current.pos.y/(1000/gridSize));
    cellMap[x][y].add(current);
  }
  
  for(int x = 0; x < gridSize; x++){
    for(int y = 0; y < gridSize; y++){
      for(int i = 0; i < cellMap[x][y].size()-1; i++){
        for(int j = i+1; j < cellMap[x][y].size(); j++){
          cellMap[x][y].get(i).collide(cellMap[x][y].get(i),cellMap[x][y].get(j),react);
        }
      }
      
      for(int i = 0; i < cellMap[x][y].size(); i++){
        for(int y1 = 0; y1 < 2; y1++){ 
          
          if(x+1 < gridSize && y+y1 > -1 && y+y1 < gridSize){
            for(int j = 0; j < cellMap[x+1][y+y1].size(); j++){
              cellMap[x][y].get(i).collide(cellMap[x][y].get(i),cellMap[x+1][y+y1].get(j),react);
            }              
          }
        }
      }
      
      for(int i = 0; i < cellMap[x][y].size(); i++){
        if(y+1 < gridSize){
          for(int j = 0; j < cellMap[x][y+1].size(); j++){
            cellMap[x][y].get(i).collide(cellMap[x][y].get(i),cellMap[x][y+1].get(j),react);
          }              
        }
      }
    }
  } 
}


class Molecule{
  
  Atom[] Atoms;
  
  PVector pos;
  PVector vel;
  
  float totalMass;
  float radius;
  float sharedOuterShell;
  float totalElectronegativity;
  boolean fullInner;
  
  String name;
  
  PImage render;
  
  boolean reacted = false;
  
  Molecule(PVector pos, PVector vel, Atom[] AtomsC){ //Each array must be created with new instanced Atoms otherwise there will be issues with reference being shared with other molecules.
    this.pos = pos.copy();
    this.vel = vel.copy();
    this.Atoms = AtomsC;
    recompute();
  }
  
  Molecule(PVector pos, PVector vel, Atom a){ //Each array must be created with new instanced Atoms otherwise there will be issues with reference being shared with other molecules.
    this.pos = pos.copy();
    this.vel = vel.copy();
    this.Atoms = new Atom[]{a};
    recompute();
  }
    
  public void recompute(){
    calculateTotalMass();
    calculateRadius();
    calculateName();
    calculateElectrons();  
    render = renderMolecule();
  }
  
  
  public void display(){
    window.image(render,pos.x-render.width/2,pos.y-render.height/2);
  }
  
  public void update(){
    pos.add(vel.x,vel.y);
    collideContainer();
  }
  
  
  public void collide(Molecule m1, Molecule m2, boolean react){
    float d = dist(m1.pos.x,m1.pos.y,m2.pos.x,m2.pos.y);
    
    if(d < (m1.radius+m2.radius)/2){
      float overlap = d - (m1.radius+m2.radius)/2;
      overlap*=-1; //Make the overlap positive so I can step the molecules forward the correct amount to stop them colliding with eachother multiple times.   
      
      //Calculates new velocities for m1 and m2, using elastic collisions.
      PVector v1 = new PVector(0,0);      
      float temp = (m1.totalMass - m2.totalMass)/(m1.totalMass+m2.totalMass);
      v1.x+=m1.vel.x*temp;
      v1.y+=m1.vel.y*temp;    
      temp = (2*m2.totalMass)/(m1.totalMass+m2.totalMass);
      v1.x+=m2.vel.x*temp;
      v1.y+=m2.vel.y*temp; 
      PVector v2 = new PVector(0,0);
      temp = (2*m1.totalMass)/(m1.totalMass+m2.totalMass);     
      v2.x+=m1.vel.x*temp;
      v2.y+=m1.vel.y*temp;     
      temp = (m2.totalMass-m1.totalMass)/(m1.totalMass+m2.totalMass);    
      v2.x+=m2.vel.x*temp;
      v2.y+=m2.vel.y*temp; 
      
      m1.vel = v1.copy();
      m2.vel = v2.copy();
      
      PVector vt = new PVector(m2.pos.x-m1.pos.x,m2.pos.y-m1.pos.y).normalize();
      
      m1.pos.x-=vt.x*overlap;
      m1.pos.y-=vt.y*overlap;
      
      m2.pos.x+=vt.x*overlap;
      m2.pos.y+=vt.y*overlap;
      
      if(react){
        m1.reacted = true;
        m2.reacted = true;
        reactWith(m1,m2);
      }
    }
  }

  
  
  
  public void reactWith(Molecule m1, Molecule m2){    
    
    Bondable[] reactants = new Bondable[m1.Atoms.length+m2.Atoms.length];
    ArrayList<ArrayList<Atom>> Bonds = new ArrayList<ArrayList<Atom>>();
    
    for(int i = 0; i < m1.Atoms.length; i++){
      reactants[i] = new Bondable(m1.Atoms[i]);
    }
    
    for(int i = 0; i < m2.Atoms.length; i++){
      reactants[m1.Atoms.length+i] = new Bondable(m2.Atoms[i]);
    }
        
    boolean reacted = true;
    
    while(reacted){
   
      float record = -1;
      int recordIndex1 = -1;
      int recordIndex2 = -1;
      
      for(int i = 0; i < reactants.length-1; i++){          //Throughout all the atoms, find the pair most likely to form a bond (the two with the most different electronegativity values.)
        for(int j = i+1; j < reactants.length; j++){
          
          
          float difference = abs(Elements[reactants[i].a.getNumber()].getElectronegativity()-Elements[reactants[j].a.getNumber()].getElectronegativity());
          
          if(difference > record && (reactants[i].canBond()) && (reactants[j].canBond())){
            record = difference;
            recordIndex1 = i;
            recordIndex2 = j;
          }
        }
      }
      
      if(record != -1){
        
        Bondable b1 = reactants[recordIndex1];
        Bondable b2 = reactants[recordIndex2];
        
        int electronShare = b1.bondCount(b2.toFill);
        
        b1.sharedElectrons += electronShare;
        
        b2.sharedElectrons += electronShare;
        
        if(b1.isBonded()){
          int indexOfBond = findIndexOfBond(b1.a,Bonds);
          Bonds.get(indexOfBond).add(b2.a);
        }else if(b2.isBonded()){
          int indexOfBond = findIndexOfBond(b2.a,Bonds);
          Bonds.get(indexOfBond).add(b1.a);          
        }else if(!(b1.isBonded() || b2.isBonded())){
          ArrayList<Atom> temp = new ArrayList<Atom>();
          temp.add(b1.a);
          temp.add(b2.a);
          Bonds.add(temp);
        }
        
        b1.bonded = true;
        b2.bonded = true;
        
        reacted = true;
      }else{
        reacted = false;
      }
    }
  
    ArrayList<Molecule> reactedMolecules = new ArrayList<Molecule>(); //Storing molecules so I can collide them afterwards to create new positions / equals velocities.
    
    for(int i = 0; i < Bonds.size(); i++){
      Atom[] atoms = new Atom[Bonds.get(i).size()];
      for(int j = 0; j < Bonds.get(i).size(); j++){
        atoms[j] = Bonds.get(i).get(j);
      }
      
      Molecule temp = new Molecule(m1.pos.add(new PVector(random(-0.1f,0.1f),random(-0.1f,0.1f))),randomVec(),atoms);
      reactedMolecules.add(temp);
    }
    
    for(int i = 0; i < reactants.length; i++){
      if(reactants[i].isBonded() == false){
        Molecule t = new Molecule(m1.pos.add(new PVector(random(-0.1f,0.1f),random(-0.1f,0.1f))),randomVec(),reactants[i].a);
        reactedMolecules.add(t);
      }
    }
    
    if(reactedMolecules.size() == 2){
      if(!(reactedMolecules.get(0).name.equals(m1.name) || reactedMolecules.get(0).name.equals(m2.name))){   //Reaction has occured.   
        Molecules.remove(m1);
        Molecules.remove(m2);
        for(int i = 0; i < reactedMolecules.size()-1; i++){
          for(int j = i+1; j < reactedMolecules.size(); j++){
            reactedMolecules.get(i).collide(reactedMolecules.get(i),reactedMolecules.get(j),false);
          }
        }   
        for(int i = 0; i < reactedMolecules.size(); i++){
          Molecules.add(reactedMolecules.get(i));
        }
      }   
    }else{ //Reaction has occured.   
      Molecules.remove(m1);
      Molecules.remove(m2);    
      for(int i = 0; i < reactedMolecules.size()-1; i++){
        for(int j = i+1; j < reactedMolecules.size(); j++){
          reactedMolecules.get(i).collide(reactedMolecules.get(i),reactedMolecules.get(j),false);
        }
      }
      
      for(int i = 0; i < reactedMolecules.size(); i++){
        Molecules.add(reactedMolecules.get(i));
      }
      
    }
  }
  
  
  public int findIndexOfBond(Atom a, ArrayList<ArrayList<Atom>> Bonds){
    
    for(int i = 0; i < Bonds.size(); i++){
      for(int j = 0; j < Bonds.get(i).size(); j++){
        if(Bonds.get(i).get(j) == a){
          return i;
        }
      }
    }
    
    return -1;
    
  }
  
  public int findMolecule(Molecule m){
    for(int i = 0; i < Molecules.size(); i++){
      if(Molecules.get(i) == m){
        return i;
      }
    }
    return 0;
  }  
  
  public void collideContainer(){
    if(pos.x+radius/2 > 999){
      pos.x = 999-radius/2;
      vel.x*=-1;
    }
    if(pos.x-radius/2 < 1){
      pos.x = 1+radius/2;
      vel.x*=-1;
    }
    if(pos.y+radius/2 > 999){
      pos.y = 999-radius/2;
      vel.y*=-1;
    }
    if(pos.y-radius/2 < 1){
      pos.y = 1+radius/2;
      vel.y*=-1;
    }
  }
  
  public void calculateTotalMass(){
    totalMass = 0;
    for(int i = 0; i < Atoms.length; i++){
      totalMass += Atoms[i].getData().AtomicMass;
    }
  }
  
  public void calculateRadius(){ //Default r for 1 = 20;
    radius = sqrt(PI*20*20*Atoms.length); //Area of circle: PI*r^(2). Calculating the radius this way allows for the Volume of the molecule to increase with the number of atoms making the reaction chance increase fairly.
  }
  
  public void calculateElectrons(){
    
    float total = 0;
    for(int i = 0; i < Atoms.length; i++){
      total+= Atoms[i].getData().getNumber();
    }
    if(total >= 2){ //removes inner shell electrons if it has them..
      total-=2;
      
      while(total > 8){
        total-=8;
      }      
      
      sharedOuterShell = total;      
      fullInner = true;
      
    }else{
      fullInner = false;
      sharedOuterShell = total;
    }
  }
  
  public void calculateElectronegativity(){
    totalElectronegativity = 0;
    
    for(int i = 0; i < Atoms.length; i++){
      totalElectronegativity+=Atoms[i].getData().getElectronegativity();
    }
  }
  
  
  public void calculateName(){
    ArrayList<String> Symbols = new ArrayList<String>();
    ArrayList<Integer> Numbers = new ArrayList<Integer>();
    for(int i = 0; i < Atoms.length; i++){
      String s = Atoms[i].getData().getSymbol();
      boolean found = false;
      for(int j = 0; j < Symbols.size(); j++){
        if(Symbols.get(j).equals(s)){
          found = true;
          Numbers.set(j,Numbers.get(j) + 1); //Increment the count of the element;
          break;
        }
      }
      if(!found){
        Symbols.add(s);
        Numbers.add(1);
      }
    }
    
    name = "";
    
    boolean swap = true;
    while(swap){
      swap = false;
      for(int i = 0; i < Numbers.size()-1; i++){
        if(Elements[Numbers.get(i)].AtomicMass > Elements[Numbers.get(i+1)].AtomicMass){
          swap = true;
          int temp = Numbers.get(i);
          Numbers.set(i,Numbers.get(i+1));
          Numbers.set(i+1,temp);
          String temp1 = Symbols.get(i);
          Symbols.set(i,Symbols.get(i+1));
          Symbols.set(i+1,temp1);
        }
      }
    }
    
    
    for(int i = 0; i < Symbols.size(); i++){
      if(Numbers.get(i) != 1){
        name = name + Symbols.get(i) + str(Numbers.get(i));
      }else{
        name = name + Symbols.get(i);
      }
    }
    
  }
  
  public void appendMolecule(Molecule m){
    Atom[] temp = new Atom[Atoms.length+m.Atoms.length];
    for(int i = 0; i < Atoms.length; i++){
      temp[i] = Atoms[i];
    }
    for(int i = Atoms.length; i < Atoms.length + m.Atoms.length; i++){
      temp[i] = m.Atoms[i-Atoms.length];
    }
    Atoms = temp;    
  }
  
  public void appendAtom(Atom a){
    Atom[] temp = new Atom[Atoms.length+1];
    for(int i = 0; i < Atoms.length; i++){
      temp[i] = Atoms[i];
    }
    temp[Atoms.length] = a;
    Atoms = temp;
  }
  
  public PImage renderMolecule(){
    moleculeRender.beginDraw();
    moleculeRender.clear();
    
    //Colourised using perlin noise, the weight of the molecule and the number of electrons in the outer shell.
    
    float angle = (totalMass/10.0f*TAU+totalElectronegativity*200);
    
    float r = max(cos(angle),0)*255;
    
    float g = max(cos(angle+TAU/3.0f),0)*255;
    
    float b = max(cos(angle+TAU/3.0f*2),0)*255;
    
    moleculeRender.fill(r,g,b);
    moleculeRender.stroke(r-30,g-30,b-30);
    moleculeRender.ellipse(moleculeRender.width/2,moleculeRender.height/2,radius,radius);
    moleculeRender.fill(0,0,0);
    moleculeRender.text(name,moleculeRender.width/2-radius/2+2,moleculeRender.height/2);
    moleculeRender.endDraw();
    return moleculeRender.copy();
  }
  
}



public int calculateOuterShell(int number){
  if(number >= 2){ //removes inner shell electrons if it has them..
    number-=2;
    
    while(number > 8){
      number-=8;
    }            
  }
  
  return number;
}


class Atom{  
  
  private int atomicNumber; //Used to interact with the Elements database in order to save memory since duplicate variables are pointless in this cenario.
  
  Atom(int atomicNumber){
    this.atomicNumber = atomicNumber-1;
  }  
  
  public int getNumber(){
    return atomicNumber;
  }
  
  public ElementData getData(){
    return Elements[atomicNumber];
  }
  
}



class Bondable{ //used in calculating reactions...
  Atom a;
  int sharedElectrons = 0;
  int toFill = 0;
  boolean bonded = false;
  
  Bondable(Atom atom){
    a = atom;
    
    if(a.getData().getNumber() > 2){
      toFill = 8 - calculateOuterShell(a.getData().getNumber()); 
    }else{
      toFill = 2 - calculateOuterShell(a.getData().getNumber()); 
    }  //Calculates how many electrons are needed to fill the outershell. Once the atom has shared that amount it will no longer be able to form bonds with other atoms (reactions are prioritised based on reactivity order).
  }
  
  public boolean canBond(){
    if(sharedElectrons < toFill){
      return true;
    }
    return false;
  }
  
  public boolean isBonded(){
    return bonded;
  }
  
  public int bondCount(int max){
    return min(max,toFill-sharedElectrons);
  }
  
}





//The "database" is a flat file database as the data i'm reading from is just element data and each of the elements is unique with regards to it's name, id, mass, electronegativty.

ElementData[] Elements;

public void initElements(){
  String[] data = loadStrings("data/Elements.txt");
  Elements = new ElementData[data.length-1];
  for(int i = 1; i < data.length; i++){
    Elements[i-1] = new ElementData(data[i]);
    Elements[i-1].printdata();
  }
}



class ElementData{ //Encapsulation prevents false data setting after loading from file.

  private String ChemicalName;
  private String ElementSymbol;
  private int AtomicNumber;
  private float AtomicMass;
  private float Electronegativity;
  
  ElementData(String data){
    String[] data2 = data.split(",");
    ChemicalName = data2[0];
    ElementSymbol = data2[1];
    AtomicNumber = PApplet.parseInt(data2[2]);
    AtomicMass = PApplet.parseFloat(data2[3]);
    Electronegativity = PApplet.parseFloat(data2[4]);
  }
  
  public String getName(){
    return ChemicalName;
  }
  
  public String getSymbol(){
    return ElementSymbol;
  }
  
  public int getNumber(){
    return AtomicNumber;
  }
  
  public float getMass(){
    return AtomicMass;
  }
  
  public float getElectronegativity(){
    return Electronegativity;
  }
  
  public void printdata(){
    println(ChemicalName,ElementSymbol,AtomicNumber,AtomicMass);
  }
}




public int findElementSymbol(String symbol){ //Finds the index within the elements array for the Symbol entered within the parameters.
  for(int i = 0; i < Elements.length; i++){
    if(Elements[i].getSymbol().equalsIgnoreCase(symbol)){
      return i;
    }
  }
  return -1;
}



public int findElementName(String name){ //Finds the index within the elements array for the Name entered within the parameters.
  for(int i = 0; i < Elements.length; i++){
    if(Elements[i].getName().equalsIgnoreCase(name)){
      return i;
    }
  }
  return -1;
}
PGraphics window;
boolean isSimulating = false;
boolean pause = false;


ArrayList<Molecule> Molecules;

public void initEnv(){
  moleculeRender = createGraphics(200,200,P2D);
  window = createGraphics(1000,1000,P2D);
  window.textFont(createFont("Consolas",64));
  Molecules = new ArrayList<Molecule>();
}


boolean running = false;

public PVector randomVec(){
  float r = random(PI*2);
  return new PVector(cos(r),sin(r));
}

public void createTempMolecules(){
  for(int i = 0; i < 30; i++){
    Molecules.add(new Molecule(new PVector(random(1000),random(1000)),randomVec(),new Atom(8)));
    Molecules.add(new Molecule(new PVector(random(1000),random(1000)),randomVec(),new Atom(1)));
    Molecules.add(new Molecule(new PVector(random(1000),random(1000)),randomVec(),new Atom(1)));
  }
  
  for(int i = 0; i < 2000; i++){
    collideMolecules(false);
    for(int j = 0; j < Molecules.size(); j++){
      Molecules.get(j).collideContainer();
    }
  }
}


public void displaySim(){
  
  window.beginDraw();
  window.background(255);
  displayMolecules();
  window.endDraw();
  stroke(150);
  strokeWeight(5);
  noFill();
  rect(460,40,1000,1000);
  image(window,460,40,1000,1000);
}



public void runSim(){
  if(running){
    updateMolecules();
    collideMolecules(true);
  }
}
UIcomp[] UIComponents;
String typeable = "abcdefghijklmnopqrstuvwxyz.0123456789_-, ()+ABCDEFGHIJKLMNOPQRSTUVWXYZ[]";

public void initUI(){
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



public void initSimUI(){
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




public void displayUI(){
  for(int i = 0; i < UIComponents.length; i++){
    UIComponents[i].display();
  }
}

public void goToSim(){
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



public String eventName(){
  for(int i = 0; i < UIComponents.length; i++){
    if(UIComponents[i].isPressed()){
      return UIComponents[i].id;
    }
  }
  return "";
}

public String[] textEvent(int k){
  for(int i = 0; i < UIComponents.length; i++){
    if(k == 10 && UIComponents[i].isSelected()){
      String temp = UIComponents[i].getContents();
      UIComponents[i].contents = "";
      return new String[]{UIComponents[i].id,temp};
    }
  } 
  return new String[]{"",""};
}



public void typeToSelected(char k){
  for(int i = 0; i < UIComponents.length; i++){
    if(UIComponents[i].isSelected() && isTypeable(str(k))){
      UIComponents[i].typeChar(str(k));
    }
    if(k == 8 && UIComponents[i].isSelected()){
      UIComponents[i].backspace();
    }
  }
}


public void parseEvent(String id){
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

public void parseTextEvent(String[] data){  //Molecule format:   symbol/name(amount) + symbol/name(amount) +... ect , amount of molecule to place into container.
  if(data[0].equals("Molecules")){    
    try{
      String[] temp = data[1].split(",");
    
      int amount = PApplet.parseInt(temp[1]);
      
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
          
          int quantity = PApplet.parseInt(elementData[1]);
          
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
    charLimit = PApplet.parseInt(sizex/14.0f);
  }
  
  public void display(){
  }
  
  public boolean isPressed(){
    return false;
  }
  
  public boolean isSelected(){
    return selected;
  }
  
  public int getCharLimit(){
    return charLimit;
  }
  
  public String getContents(){
    return contents;
  }
  
  public void typeChar(String k){
    if(contents.length() < charLimit){
      contents = contents + k;
    }
  }
  
  public void backspace(){
    if(contents.length() > 0){
      contents = contents.substring(0,contents.length()-1);
    }
  }
  
  public void setVisibility(boolean state){
    visible = state;
  }
  
  public void setFontSize(int size){
    fontSize = size;
  }
}


class Button extends UIcomp{
  
  Button(String id, PVector pos, int x, int y){
    super(id,pos,x,y);
  }
  
  public void display(){
    if(visible){
      fill(50);
      stroke(200);
      rect(pos.x,pos.y,sizex,sizey);
      fill(255);
      textSize(fontSize);
      text(id,pos.x+2,pos.y+fontSize);
    }
  }
  
  public boolean isPressed(){
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
 
  public void display(){
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
  
  public boolean isPressed(){
    if((mouseX > pos.x && mouseY > pos.y) && (mouseX < pos.x+sizex && mouseY < pos.y+sizey) && visible){
      println("Clicked"+id);
      selected = true;
      return true;
    }
    selected = false;
    return false;
  }
  
  
  public void setFontSize(int size){
    fontSize = size;
    charLimit = PApplet.parseInt(sizex/PApplet.parseFloat(size))*2-1;
  }
}


public boolean isTypeable(String k){
  for(int i = 0; i < typeable.length(); i++){
    if(typeable.substring(i,i+1).equals(k)){
      return true;
    }
  }
  return false;
}
  public void settings() {  fullScreen(P2D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "Atomics" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
