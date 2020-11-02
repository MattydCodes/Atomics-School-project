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
  
  ElementData(String data){
    String[] data2 = data.split(",");
    ChemicalName = data2[0];
    ElementSymbol = data2[1];
    AtomicNumber = int(data2[2]);
    AtomicMass = float(data2[3]);
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
  
  void printdata(){
    println(ChemicalName,ElementSymbol,AtomicNumber,AtomicMass);
  }
}
