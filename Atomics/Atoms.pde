//Molecules will contain an array of Atoms.
//Each Molecule will start off with just 1 atom unless speicified otherwise.


//Molecules will be represented with slightly bigger circles based on how many atoms there are in the molecule. So that the area is equal to the total of all the atoms area.


//In order to optimise the collision process from being O(n^2), I will create a "cell" map of the container and place each Molecule into the correct cell, it will then only need to check for collisions with it's neighbouring cells.



void updateMolecules(){
  for(int i = 0; i < Molecules.size(); i++){
    Molecules.get(i).update();
  }
}

void displayMolecules(){
  for(int i = 0; i < Molecules.size(); i++){
    Molecules.get(i).display();
  }
}

void collideMolecules(){
  
  ArrayList<Molecule>[][] cellMap = new ArrayList[10][10];
  
  for(int x = 0; x < 10; x++){
    for(int y = 0; y < 10; y++){
      cellMap[x][y] = new ArrayList<Molecule>();
    }
  }
  
  for(int i = 0; i < Molecules.size(); i++){
    Molecule current = Molecules.get(i);
    int x = int(current.pos.x/100);
    int y = int(current.pos.y/100);
    cellMap[x][y].add(current);
  }
  
  for(int i = 0; i < Molecules.size(); i++){
    Molecules.get(i).collideMap(cellMap);
  }
  
}


class Molecule{
  
  Atom[] Atoms;
  
  PVector pos;
  PVector vel;
  
  float totalMass;
  float radius;
  float sharedOuterShell;
  boolean fullInner;
  
  String name;
  
  PImage render;
  
  
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
    
  void recompute(){
    calculateTotalMass();
    calculateRadius();
    calculateName();
    render = renderMolecule();
    calculateElectrons();    
  }
  
  
  void display(){
    window.image(render,pos.x-radius/2,pos.y-radius/2);
  }
  
  void update(){
    pos.add(vel.x,vel.y);
    collideContainer();
  }
 
 
 
 
 
 
 
 
 
  void collideMap(ArrayList<Molecule>[][] map){
    int x = int(pos.x/100);
    int y = int(pos.y/100);
    for(int x1 = -1; x1 < 2; x1++){
      int x2 = constrain(x1+x,0,9);
      for(int y1 = -1; y1 < 2; y1++){
        int y2 = constrain(y1+y,0,9);
        for(int i = 0; i < map[x2][y2].size(); i++){
          if(map[x2][y2].get(i) != this){
            collide(this,map[x2][y2].get(i));
          }
        }
      }
    }
  }
  
  
  void collide(Molecule m1, Molecule m2){
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
      
      reactWith(m1,m2);
    }
  }
  
  void reactWith(Molecule m1, Molecule m2){
    if(m1.sharedOuterShell + m2.sharedOuterShell == 2 && m1.fullInner == false && m2.fullInner == false){
      int index = findMolecule(m2);
      appendMolecule(m2);
      Molecules.remove(index);
      recompute();
    }
    
    if(m1.sharedOuterShell + m2.sharedOuterShell == 6 && m1.fullInner == true && m2.fullInner == true){
      int index = findMolecule(m2);
      appendMolecule(m2);
      Molecules.remove(index);
      recompute();
    }
  }
  
  int findMolecule(Molecule m){
    for(int i = 0; i < Molecules.size(); i++){
      if(Molecules.get(i) == m){
        return i;
      }
    }
    return 0;
  }
  
  void collideContainer(){
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
  
  void calculateTotalMass(){
    totalMass = 0;
    for(int i = 0; i < Atoms.length; i++){
      totalMass += Elements[Atoms[i].getNumber()].AtomicMass;
    }
  }
  
  void calculateRadius(){ //Default r for 1 = 20;
    radius = sqrt(PI*20*20*Atoms.length); //Area of circle: PI*r^(2).
  }
  
  void calculateElectrons(){
    
    float total = 0;
    for(int i = 0; i < Atoms.length; i++){
      total+=Elements[Atoms[i].getNumber()].getNumber();
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
  
  void calculateName(){
    ArrayList<String> Symbols = new ArrayList<String>();
    ArrayList<Integer> Numbers = new ArrayList<Integer>();
    for(int i = 0; i < Atoms.length; i++){
      String s = Elements[Atoms[i].getNumber()].getSymbol();
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
  
  void appendMolecule(Molecule m){
    Atom[] temp = new Atom[Atoms.length+m.Atoms.length];
    for(int i = 0; i < Atoms.length; i++){
      temp[i] = Atoms[i];
    }
    for(int i = Atoms.length; i < Atoms.length + m.Atoms.length; i++){
      temp[i] = m.Atoms[i-Atoms.length];
    }
    Atoms = temp;    
  }
  
  void appendAtom(Atom a){
    Atom[] temp = new Atom[Atoms.length+1];
    for(int i = 0; i < Atoms.length; i++){
      temp[i] = Atoms[i];
    }
    temp[Atoms.length] = a;
    Atoms = temp;
  }
  
  PImage renderMolecule(){
    PGraphics scene = createGraphics(int(radius+1),int(radius+1),P2D);
    scene.beginDraw();
    scene.clear();
    scene.fill(0,0,0);
    scene.ellipse(radius/2,radius/2,radius,radius);
    scene.fill(255,255,255);
    scene.text(name,2,radius/2);
    scene.endDraw();
    return scene;
  }
  
}



class Atom{  
  
  private int atomicNumber; //Used to interact with the Elements database in order to save memory since duplicate variables are pointless in this cenario.
  
  Atom(int atomicNumber){
    this.atomicNumber = atomicNumber-1;
  }  
  
  int getNumber(){
    return atomicNumber;
  }
  
  
}
