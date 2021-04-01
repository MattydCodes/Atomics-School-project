//Molecules will contain an array of Atoms.
//Each Molecule will start off with just 1 atom unless speicified otherwise.


//Molecules will be represented with slightly bigger circles based on how many atoms there are in the molecule. So that the area is equal to the total of all the atoms area.


//In order to optimise the collision process from being O(n^2), I will create a "cell" map of the container and place each Molecule into the correct cell, it will then only need to check for collisions with it's neighbouring cells.

PGraphics moleculeRender;

void updateMolecules(){ // Runs the update() method on each molecule in the Molecules ArrayList.
  for(int i = 0; i < Molecules.size(); i++){
    Molecules.get(i).update(); 
  }
}

void displayMolecules(){ //Runs the display() method on each molecule in the Molecules ArrayList.
  for(int i = 0; i < Molecules.size(); i++){
    Molecules.get(i).display();
  }
}

void collideMolecules(boolean react){ //Collides the Molecules, with the parameter "react" being used to tell the program if reactions should take place or not.
  
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
    int x = int(current.pos.x/(1000/gridSize));
    int y = int(current.pos.y/(1000/gridSize));
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
    
  void recompute(){
    calculateTotalMass();
    calculateRadius();
    calculateName();
    calculateElectrons();  
    render = renderMolecule();
  }
  
  
  void display(){
    window.image(render,pos.x-render.width/2,pos.y-render.height/2);
  }
  
  void update(){
    pos.add(vel.x,vel.y);
    collideContainer();
  }
  
  
  void collide(Molecule m1, Molecule m2, boolean react){
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

  
  
  
  void reactWith(Molecule m1, Molecule m2){    
    
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
      
      Molecule temp = new Molecule(m1.pos.add(new PVector(random(-0.1,0.1),random(-0.1,0.1))),randomVec(),atoms);
      reactedMolecules.add(temp);
    }
    
    for(int i = 0; i < reactants.length; i++){
      if(reactants[i].isBonded() == false){
        Molecule t = new Molecule(m1.pos.add(new PVector(random(-0.1,0.1),random(-0.1,0.1))),randomVec(),reactants[i].a);
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
  
  
  int findIndexOfBond(Atom a, ArrayList<ArrayList<Atom>> Bonds){
    
    for(int i = 0; i < Bonds.size(); i++){
      for(int j = 0; j < Bonds.get(i).size(); j++){
        if(Bonds.get(i).get(j) == a){
          return i;
        }
      }
    }
    
    return -1;
    
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
      totalMass += Atoms[i].getData().AtomicMass;
    }
  }
  
  void calculateRadius(){ //Default r for 1 = 20;
    radius = sqrt(PI*20*20*Atoms.length); //Area of circle: PI*r^(2). Calculating the radius this way allows for the Volume of the molecule to increase with the number of atoms making the reaction chance increase fairly.
  }
  
  void calculateElectrons(){
    
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
  
  void calculateElectronegativity(){
    totalElectronegativity = 0;
    
    for(int i = 0; i < Atoms.length; i++){
      totalElectronegativity+=Atoms[i].getData().getElectronegativity();
    }
  }
  
  
  void calculateName(){
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
    moleculeRender.beginDraw();
    moleculeRender.clear();
    
    //Colourised using perlin noise, the weight of the molecule and the number of electrons in the outer shell.
    
    float angle = (totalMass/10.0*TAU+totalElectronegativity*200);
    
    float r = max(cos(angle),0)*255;
    
    float g = max(cos(angle+TAU/3.0),0)*255;
    
    float b = max(cos(angle+TAU/3.0*2),0)*255;
    
    moleculeRender.fill(r,g,b);
    moleculeRender.stroke(r-30,g-30,b-30);
    moleculeRender.ellipse(moleculeRender.width/2,moleculeRender.height/2,radius,radius);
    moleculeRender.fill(0,0,0);
    moleculeRender.text(name,moleculeRender.width/2-radius/2+2,moleculeRender.height/2);
    moleculeRender.endDraw();
    return moleculeRender.copy();
  }
  
}



int calculateOuterShell(int number){
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
  
  int getNumber(){
    return atomicNumber;
  }
  
  ElementData getData(){
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
  
  boolean canBond(){
    if(sharedElectrons < toFill){
      return true;
    }
    return false;
  }
  
  boolean isBonded(){
    return bonded;
  }
  
  int bondCount(int max){
    return min(max,toFill-sharedElectrons);
  }
  
}
