//The "database" is a flat file database as the data i'm reading from is just element data and each of the elements is unique with regards to it's name, id, mass, electronegativty.

ElementData[] Elements;

void initElements(){
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
    AtomicNumber = int(data2[2]);
    AtomicMass = float(data2[3]);
    Electronegativity = float(data2[4]);
  }
  
  String getName(){
    return ChemicalName;
  }
  
  String getSymbol(){
    return ElementSymbol;
  }
  
  int getNumber(){
    return AtomicNumber;
  }
  
  float getMass(){
    return AtomicMass;
  }
  
  float getElectronegativity(){
    return Electronegativity;
  }
  
  void printdata(){
    println(ChemicalName,ElementSymbol,AtomicNumber,AtomicMass);
  }
}




int findElementSymbol(String symbol){ //Finds the index within the elements array for the Symbol entered within the parameters.
  for(int i = 0; i < Elements.length; i++){
    if(Elements[i].getSymbol().equalsIgnoreCase(symbol)){
      return i;
    }
  }
  return -1;
}



int findElementName(String name){ //Finds the index within the elements array for the Name entered within the parameters.
  for(int i = 0; i < Elements.length; i++){
    if(Elements[i].getName().equalsIgnoreCase(name)){
      return i;
    }
  }
  return -1;
}
