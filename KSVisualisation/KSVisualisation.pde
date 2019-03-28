//All code for the histogram is done by Tejas Hegde. It is better off in a class tbh
//This code is in many cases sub-optimal, and should not be used as a reference
//It is however, original

//ControlP5 is an external library I have nothing to do with
import controlP5.*;
import java.util.Arrays;
import java.util.Map;
import java.lang.Integer;

float PADDING = 10;
float BOTTOMBAR = 40;
float SIDEBAR;
float gWidth; 
float gHeight;
float gXLoc;
float gYLoc;
int ksPrimCol = color(3,71,82);
boolean isNumber(char c){
  return ((c>='0')&&(c <= '9'));
}

boolean isNumber(String s){
  boolean decimal = false;
  char c = s.charAt(0);
  //only allow a negative sign at the front.
  if(c!='-'){
    if(!isNumber(c)){
      return false;
    }
  }
  
  for(int i = 1; i < s.length(); i++){
    c = s.charAt(i);
    if(!isNumber(c)){
      if(!decimal){
        if(c == '.'){
          decimal = true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    }
  } 
  return true;
}

//Was going to use this to randomly generate colors for different categories
//but I never got that far :(
int generateHue(float d){
  float X = 1 - abs((d/60 % 2) - 1);
  if(d < 60){
    return color(255,255*X,0);
  } else if(d < 120){
    return color(255*X,255,0);
  }else if(d < 180){
    return color(0,255,255*X);
  }else if(d < 240){
    return color(0,255*X,255);
  }else if(d < 300){
    return color(255*X,0,255);
  }else{
    return color(255,0,255*X);
  }
}

//A way to store graph settings for each visualisation, and measure of success
class GraphSettings{
  public float dMin = 0;
  public float dMax = 10;
  public float rMin = 0;
  public float rMax = 10;
  
  public void set(GraphSettings other){
    dMin = other.dMin;
    dMax = other.dMax;
    rMin = other.rMin;
    rMax = other.rMax;
  }
}

//getters and setters to make things easier
void setRMin(float val){
  if(currentMeasure < visPresets.length){
    visPresets[currentMeasure].rMin = val;
  }
}

void setRMax(float val){
  if(currentMeasure < visPresets.length){
    visPresets[currentMeasure].rMax = val;
  }
}
void setDMin(float val){
  if(currentMeasure < visPresets.length){
    visPresets[currentMeasure].dMin = val;
  }
}
void setDMax(float val){
  if(currentMeasure < visPresets.length){
    visPresets[currentMeasure].dMax = val;
  }
}

float getRMin(){ return visPresets[currentMeasure].rMin; }
float getRMax(){ return visPresets[currentMeasure].rMax; }
float getDMin(){ return visPresets[currentMeasure].dMin; }
float getDMax(){ return visPresets[currentMeasure].dMax; }

int currentMeasure = 0;
//could use a class called MeasureOfSuccess and have a single array, but a little late for that 
String[] measuresOfSuccess = {"%funded", "usd_pledged_real", "backers", "duration(Days)", "usd_goal_real"};
String[] measuresOfSuccessAKA = {"% funded", "Money pledged (USD)", "No. of backers", "Time taken", "Funding goal(USD)"};
String[] measuresOfSuccessUnits = {" %", "USD", "", " days", "USD"};

//I was going to comment every line but I only now realised how time consuming that would be
DropdownList measuresOfSuccessDropdown;
GraphSettings[] visPresets;
GraphSettings[] initVisPresets;

ControlFont largeFont;

Range rTimeWindow;

float toGraphX(float x){
  float dMin = getDMin();
  float dMax = getDMax();
  return ((x - gXLoc)*(dMax-dMin))/(gWidth) + dMin;
}

float toGraphY(float y){
  float rMax = getRMax();
  float rMin = getRMin();
  return ((gHeight-y+gYLoc)*(rMax - rMin))/(gHeight) + rMin;
}

float toScreenX(float x){
  float dMin = getDMin();
  float dMax = getDMax();
  return ((x-dMin)/(dMax-dMin)) * gWidth + gXLoc;
}

float toScreenY(float y){
  float rMax = getRMax();
  float rMin = getRMin();
  return ((rMax-y-rMin)/(rMax-rMin)) * gHeight + gYLoc;
}

ControlP5 cp5;

Table csv;
HashMap<String,HashMap<String,DataPoint>> categoryTree = new HashMap<String,HashMap<String,DataPoint>>();
HashMap<String,Group> categoryGroups = new HashMap<String,Group>();
Accordion categorySidebar;
Toggle AllAll;
Textlabel graphTitle;
PImage helpImg;
Toggle useAverage;
Textlabel qsTitle;
Textfield minTextbox;
Textfield maxTextbox;

class DataPoint{
  public Toggle uiToggle;
  public boolean shouldInclude(){
    return uiToggle.getState();
  }
}

ArrayList[] catGroups;

int getDateIndex(float date){ 
  
  int n = csv.getRowCount();
  
  //typical binary search
  int a = 0, b = n - 1;
  while(b > 1){
    if(a+b/2 < n){
      if(csv.getFloat(a + b/2, "launchedNumeric") < date){
        a += b/2;
      }
      else{
        b/=2;
      }
    }else{
      b/=2;
    }
  }
  return a;
}

int numCategories = 0;
int numSubCategories = 0;
GraphSettings helpGPreset = new GraphSettings();

void setup(){
  size(1254,612);
  cp5 = new ControlP5(this);
  cp5.setColorBackground(ksPrimCol);
  largeFont = new ControlFont(createFont("Arial",20),18);
  visPresets = new GraphSettings[measuresOfSuccess.length];
  initVisPresets = new GraphSettings[measuresOfSuccess.length];
  for(int i = 0; i < visPresets.length;i++){
    visPresets[i]=new GraphSettings();
    initVisPresets[i] = new GraphSettings();
  }
  //%Success initial view
  initVisPresets[0].dMin = 0;
  initVisPresets[0].dMax = numBars * 5;
  
  for(int i = 0; i < visPresets.length;i++){
    visPresets[i].set(initVisPresets[i]);
  }
  
  /*
  gWidth = width - 3*PADDING - SIDEBAR;
  gHeight = height - 9*PADDING-BOTTOMBAR;
  gXLoc = 8*PADDING;
  gYLoc = 4*PADDING;
  SIDEBAR = width - 2 * PADDING - gXLoc - gWidth;
  */
  
  gXLoc = 8*PADDING + 130;
  gYLoc = 4*PADDING;
  gWidth = width - 150 - gXLoc;
  gHeight = height - 9*PADDING-BOTTOMBAR;
  SIDEBAR = 130;
  
  csv = loadTable("ks-projects-201801.csv","csv,header");
  helpImg = loadImage("help.png");
  helpGPreset.dMax = gWidth;
  helpGPreset.rMax = gHeight;
  
  cp5.addLabel("CategoriesLabel")
      .setPosition(width-SIDEBAR-PADDING, PADDING)
      .setText("Categories")
      .setFont(largeFont);
      
  qsTitle = cp5.addLabel("Quick Stats")
    .setPosition(PADDING, PADDING)
    .setFont(largeFont);
      
  graphTitle = cp5.addLabel("GraphTitle")
      .setPosition(gXLoc + PADDING, PADDING)
      .setText(">Title goes here<")
      .setFont(largeFont);
      
  categorySidebar = cp5.addAccordion("Sidabar")
        .setPosition(gXLoc + gWidth+PADDING, 2*PADDING+20)
        .setWidth(round(SIDEBAR));
  
  for(int i = 0; i < csv.getRowCount(); i++){
    String cat = csv.getString(i, "main_category");
    if(!categoryTree.containsKey(cat)){
      categoryTree.put(cat,new HashMap<String, DataPoint>());
      Group g = cp5.addGroup(cat+"grp").setBackgroundColor(color(0,150)).setLabel(cat);
      categorySidebar.addItem(g);
      categoryGroups.put(cat,g);
      numCategories++;
    }
    
    String subCat = csv.getString(i, "category");
    if(!categoryTree.get(cat).containsKey(subCat)){
      Toggle t = cp5.addToggle(cat+subCat)
                                           .setSize(10,10)
                                           .setPosition(PADDING,PADDING+categoryTree.get(cat).size()*15)
                                           .moveTo(categoryGroups.get(cat))
                                           .setValue(true)   
                                           .setLabel(subCat)
        .addCallback(new CallbackListener(){
          public void controlEvent(CallbackEvent theEvent){
            if(theEvent.getAction() == ControlP5.ACTION_BROADCAST){
              recalc = true;
            }
          }
        });
      
      Label l = t.getCaptionLabel();
      l.getStyle().marginTop = -14;
      l.getStyle().marginLeft = 15;
      
      DataPoint data = new DataPoint();
      data.uiToggle = t;
      categoryTree.get(cat).put(subCat, data);
      numSubCategories++;
    }
  }
  
  for(String k : categoryTree.keySet()){
    final String s = k;
    final Toggle t = cp5.addToggle(k+"ALL")
                     .setSize(15,15)
                     .setPosition(PADDING,PADDING+categoryTree.get(k).size()*15)
                     .moveTo(categoryGroups.get(k))
                     .setValue(true)   
                     .setLabel("ALL");
                     
    t.addCallback(new CallbackListener(){
      public void controlEvent(CallbackEvent theEvent){
        if(theEvent.getAction() == ControlP5.ACTION_BROADCAST){
          HashMap<String,DataPoint> m = categoryTree.get(s);
          boolean stateBool = !m.get(m.keySet().toArray()[0]).shouldInclude();
          for(String k2 : m.keySet()){
            m.get(k2).uiToggle.setState(stateBool);
          }
          t.setBroadcast(false);
          t.setState(stateBool);
          t.setBroadcast(true);
          recalc = true;
        }
      }
    });
    
    Label l = t.getCaptionLabel();
    l.getStyle().marginTop = -16;
    l.getStyle().marginLeft = 17;
                
  }
  
  for(String k : categoryGroups.keySet()){
    categoryGroups.get(k)
        .setBackgroundHeight(round(PADDING + categoryTree.get(k).size()*15 + 15 + PADDING));
  }
  
  rTimeWindow = cp5.addRange("Time Window")
      .setBroadcast(false)
      .setPosition(gXLoc, height - 4*PADDING)
      .setSize(round(gWidth), round(3*PADDING))
      .setHandleSize(20)
      .setRange(csv.getInt(0,"launchedNumeric"),csv.getInt(csv.getRowCount()-1,"launchedNumeric"))
      ;
      
  rTimeWindow.setLowValueLabel(csv.getString(getDateIndex(rTimeWindow.getLowValue()),"launched"))
      .setHighValueLabel(csv.getString(getDateIndex(rTimeWindow.getHighValue()),"launched"))
      .setBroadcast(true);
  
  PFont f = createFont("Arial",10);
  rTimeWindow.getValueLabel()
    .setFont(f);
  rTimeWindow.getCaptionLabel().setFont(f);
  
  
  rTimeWindow.setRangeValues(rTimeWindow.getMin(),rTimeWindow.getMax());
  
  AllAll = cp5.addToggle("ALLALLToggle")
                      .setPosition(width - SIDEBAR - PADDING,  gYLoc + categoryTree.size()*10 + PADDING)
                      .setSize(20,20)
                      .setState(true)
                      .setLabel("Toggle All Categories")
                      .addCallback(
                      new CallbackListener(){
                        public void controlEvent(CallbackEvent theEvent){
                          if(theEvent.getAction()==ControlP5.ACTION_BROADCAST){
                            recalc = true;
                            for(String k : categoryTree.keySet()){
                              for(String k2 : categoryTree.get(k).keySet()){
                                categoryTree.get(k).get(k2).uiToggle.setState(AllAll.getState());
                              }
                            }
                          }
                        }
                      }
                      );
  Label l = AllAll.getCaptionLabel();
  l.getStyle().marginTop = -20;
  l.getStyle().marginLeft = 24;
  
  //////////////CALLBACKS////////////////iwouldusuallyneverdothisblockofforwardslashesbutihadtomakeanexceptionthistimesincethisstuffwasquiteimportant///
  rTimeWindow.addCallback(new CallbackListener(){
    public void controlEvent(CallbackEvent theEvent){
      if(theEvent.getAction()== ControlP5.ACTION_BROADCAST){
        recalc = true;
        rTimeWindow.setLowValueLabel(csv.getString(getDateIndex(rTimeWindow.getLowValue()),"launched"));
        rTimeWindow.setHighValueLabel(csv.getString(getDateIndex(rTimeWindow.getHighValue()),"launched"));
      }
    }
  });
  
  cp5.addButton("RevertViewButton")
        .setPosition(gXLoc + gWidth - 20, gYLoc+1)
        .setSize(20,20)
        .setLabel("<=")
        .addCallback(new CallbackListener(){
          public void controlEvent(CallbackEvent theEvent){
            if(theEvent.getAction()== ControlP5.ACTION_BROADCAST){
              visPresets[currentMeasure].set(initVisPresets[currentMeasure]);
              println(getDMax());
              recalc = true;
            }
          }
        });
        
                
  useAverage = cp5.addToggle("Normalized data")
      .setPosition(gXLoc + gWidth + PADDING, AllAll.getPosition()[1] + PADDING + 20)
      .setSize(20,20)
      .addCallback(new CallbackListener(){
          public void controlEvent(CallbackEvent theEvent){
            if(theEvent.getAction()== ControlP5.ACTION_BROADCAST){
              recalc = true;
            }
          }
        });
  
  l = useAverage.getCaptionLabel();
  l.getStyle().marginTop = -20;
  l.getStyle().marginLeft = 24;

  Textlabel l2 = cp5.addLabel("Measure of success")
     .setText("Measure \nof Success")
     .setFont(largeFont)
     .setPosition(gXLoc + gWidth + PADDING, useAverage.getPosition()[1]+20+PADDING)     
     ;     

  measuresOfSuccessDropdown = cp5.addDropdownList("MeasureChoices")
      .setPosition(gXLoc + gWidth + PADDING, l2.getPosition()[1] + 45 + PADDING)
      .setWidth(round(SIDEBAR))
      .addCallback(new CallbackListener(){
          public void controlEvent(CallbackEvent theEvent){
            if(theEvent.getAction()== ControlP5.ACTION_BROADCAST){
              currentMeasure = round(measuresOfSuccessDropdown.getValue());
              recalc = true;
            }
          }
        })
      .setLabel("%funded")
      .close();
  for(int i = 0; i < measuresOfSuccess.length;i++){
    measuresOfSuccessDropdown.addItem(measuresOfSuccessAKA[i],i);
  }
  
  cp5.addButton("Help!")
      .setPosition(gXLoc + gWidth + PADDING, gYLoc + gHeight - 20)
      .setSize(round(SIDEBAR), 20)
      .addCallback(new CallbackListener(){
          public void controlEvent(CallbackEvent theEvent){
            if(theEvent.getAction()== ControlP5.ACTION_BROADCAST){
              if(visualisationNumber == 0){
                exitHelp();
              } else {
                setDMin(0);
                setDMax(gWidth);
                setRMin(0);
                setRMax(gHeight);
                prevVisualisation = visualisationNumber;
                visualisationNumber = 0;
                recalc = true;
              }
            }
          }
        });
  
        
  minTextbox = cp5.addTextfield("Domain Minimum")
     .setPosition(gXLoc + gWidth + PADDING, gYLoc + gHeight - 130)
     .setSize(round(SIDEBAR),round(2*PADDING))
     .setFont(createFont("arial",10))
     .setAutoClear(false)
     .addCallback(new CallbackListener(){
          public void controlEvent(CallbackEvent theEvent){
            //100 is the event that fires once we input text
            if(theEvent.getAction() == 100){
              if(isNumber(minTextbox.getText())){
                float f = parseFloat(minTextbox.getText());
                if(f >= getDMax()){
                  minTextbox.setText(nf(getDMin(), 0, 2));
                } else {
                  setDMin(f);
                  recalc = true;
                }
              } else {
                minTextbox.setText(nf(getDMin(), 0, 2));
              }
            }else if(theEvent.getAction() == ControlP5.ACTION_CLICK){
              minTextbox.setText("");
            }
          }
        });
     
        
  maxTextbox = cp5.addTextfield("Domain Maximum")
     .setPosition(gXLoc + gWidth + PADDING, gYLoc + gHeight - 80)
     .setSize(round(SIDEBAR),round(2*PADDING))
     .setFont(createFont("arial",10))
     .setAutoClear(false)
          .addCallback(new CallbackListener(){
          public void controlEvent(CallbackEvent theEvent){
            //100 is the event that fires once we input text
            if(theEvent.getAction() == 100){
              if(isNumber(maxTextbox.getText())){
                float f = parseFloat(maxTextbox.getText());
                if(f <= getDMin()){
                  maxTextbox.setText(nf(getDMax(), 0, 2));
                } else {
                  setDMax(f);
                  recalc = true;
                }
              } else {
                maxTextbox.setText(nf(getDMax(), 0, 2));
              }
            } else if(theEvent.getAction() == ControlP5.ACTION_CLICK){
              maxTextbox.setText("");
            }
          }
        });
     
  
  categorySidebar.bringToFront();
  
  for(String k : categoryGroups.keySet()){
    categoryGroups.get(k).bringToFront();
  }
  
  for(String k : categoryTree.keySet()){
    for(String k2 : categoryTree.get(k).keySet()){
      categoryTree.get(k).get(k2).uiToggle.bringToFront();
    }
  }
}

boolean mouseOver(float x, float y, float w, float h){
  if((mouseX > x)&&(mouseX < x+w)){
    if((mouseY > y)&&(mouseY < y+h)){
      return true;
    }
  }
  return false;
}

int[][] histFBins;
int numBars = 100;
int splitMode = 3;
boolean splitModeChanged = true;
int lClip = 0;
int rClip = 0;

float[] totals;
int[] numProj;
//these are not trivial lmao
//float median = 0;
//float mode = 0;
float upperQuartile = 0;
float lowerQuartile = 0;
int[] top10 = new int[10];
int[] bottom10 = new int[10];

void calculateHistogram(){
  if((histFBins==null)||splitModeChanged){
    if(histFBins==null){
      setDMax(visPresets[currentMeasure].dMax);
      setDMin(0);    
    }
    
    if(splitMode==0){
      histFBins = new int[1][numBars];
      totals = new float[2];
      numProj = new int[1];
    } else if(splitMode == 1){
      histFBins = new int[numCategories][numBars];
      totals = new float[numCategories+1];
      numProj = new int[numCategories];
    } else if(splitMode == 2){
      histFBins = new int[numSubCategories][numBars];
      totals = new float[numSubCategories+1];
      numProj = new int[numSubCategories];
    } else{
      histFBins = new int[3][numBars];
      totals = new float[4];
      numProj = new int[3];
    }
  } else {
    for(int i = 0; i < histFBins.length;i++){
      Arrays.fill(histFBins[i], 0);
    }
  }

  setRMin(0);
  float binWidth = (getDMax()-getDMin())/(histFBins[0].length);
  float ourDMin = floor(getDMin() / binWidth)*binWidth;
  int maxFrequ = 10;
  int n = getDateIndex(rTimeWindow.getHighValue());
  int n0 = getDateIndex(rTimeWindow.getLowValue());
  lClip = 0;
  rClip = 0;
  Arrays.fill(totals,0);
  Arrays.fill(numProj, 0);
  //median = 0;
  //mode = 0;
  upperQuartile = 0;
  lowerQuartile = 0;
  Arrays.fill(top10,-1);
  Arrays.fill(bottom10,-1);
  
  String title = "Distribution of " + measuresOfSuccessAKA[currentMeasure] + " for all Kickstarter projects from " + csv.getString(n0,"launched") + " to " + csv.getString(n, "launched");
  graphTitle.setText(title);
  title = "Quick Stats\n> " + measuresOfSuccessAKA[currentMeasure];
  qsTitle.setText(title);
  //iterate through every project in the range
  for(int i = n0; i < n; i++){
    String cat = csv.getString(i,"main_category");
    String subCat = csv.getString(i,"category");
    if(categoryTree.get(cat).get(subCat).shouldInclude()){
      //All as one big lump
      if(splitMode == 0){
        float f = csv.getFloat(i,measuresOfSuccess[currentMeasure]);
        int index = floor(((f-ourDMin)/binWidth));
        if(index >= 0){
          if(index < histFBins[0].length){
            histFBins[0][index]++;
            maxFrequ = max(maxFrequ,histFBins[0][index]);
            totals[0] += f;
            numProj[0]++;
            
            
          } else {
            rClip++;
            //got clipped to the right
          }
        } else {
          //got clipped to the left
          lClip++;
        }
        
      } 
      //Eeach category is a different color
      else if (splitMode == 1){
        
      } 
      //Each subcategory is a different color
      else if (splitMode == 2){
        
        
      }
      //successful, failed and other are a different color
      else if (splitMode==3){
        String state = csv.getString(i,"state");
        int series;
        char c = state.charAt(0);
        if(c =='s'){
          series = 0;
        } else if(c=='f'){
          series = 1;
        } else {
          series = 2;
        }
        float f = csv.getFloat(i,measuresOfSuccess[currentMeasure]);
        int index = floor(((f-ourDMin)/binWidth));
        if(index >= 0){
          if(index < histFBins[series].length){
            totals[0] += f;
            histFBins[series][index]++;
            totals[series+1] += f;
            numProj[series]++;
            int sum = 0;
            for(int j = 0; j < histFBins.length; j++){
              sum += histFBins[j][index];
            }
            maxFrequ = max(maxFrequ,sum);
            
            //find if it belongs in top 10
            int pos = top10.length;
            while(pos > 0){
              if(top10[pos - 1] < 0){
                pos--;
                continue;
              }
              
              if(csv.getFloat(top10[pos-1], measuresOfSuccess[currentMeasure]) < f){
                pos--;
                if(pos < top10.length-1){
                  //move the old value down
                  top10[pos + 1] = top10[pos];
                }
              } else {
                break;
              }
            }
            if(pos < top10.length){
              top10[pos] = i;
            }
            
            //Find out if it belongs in the bottom 10;
            pos = -1;
            while(pos < bottom10.length - 1){
              if(bottom10[pos + 1] < 0){
                pos++;
                continue;
              }
              
              if(csv.getFloat(bottom10[pos+1], measuresOfSuccess[currentMeasure]) > f){
                pos++;
                if(pos > 0){
                  //move the old value down
                  bottom10[pos - 1] = bottom10[pos];
                }
              } else {
                break;
              }
            }
            if(pos >= 0){
              bottom10[pos] = i;
            }
          } else {
            //got clipped to the right
            rClip++;
          }
        } else {
          //got clipped to the left
          lClip++;
        }
      }
    }
  }
  
  maxTextbox.setText(nf(getDMax(), 0, 2));
  minTextbox.setText(nf(getDMin(), 0, 2));
  
  if(useAverage.getState()){
    setRMax(1);
  } else {
    setRMax(maxFrequ + 10);
  }
}

void drawYTicks(String label){
  float logarithm = log(getRMax() - getRMin())/log(10);
  float scale = 0;
  if(logarithm % 1.0 < 0.7){
    scale = pow(10,floor(logarithm)-1);
  } else{
    scale = pow(10,floor(logarithm));
  }
  textAlign(RIGHT);
  int n = floor((getRMax() - getRMin())/scale);
  for(int i = 0; i < n; i++){
    float f = getRMin() + i * scale;
    if(f > 99999){
      if(i%2==0){
        continue;
      }
    }
    float y1 = toScreenY(f);
    text(str(round(f)) + " ",gXLoc, y1+5);
    line(gXLoc - 2, y1, gXLoc, y1);
  }
  text(str(round(getRMax())) + " ", gXLoc, toScreenY(getRMax())+5);
  pushMatrix();
  translate(gXLoc - 60, gYLoc + gHeight/2);
  rotate(-PI/2);
  text(label, 0, 0);
  popMatrix();
}

void drawHistogram(){
  //Recalculate the bins if necessary
  if(recalc){
    recalc = false;
    calculateHistogram();
  }
  drawYTicks("Frequency");
  //drawLegend(gXLoc + PADDING, gYLoc + PADDING);
  
  int n = histFBins[0].length;
  float w = (getDMax()-getDMin())/n;
  float ourDMin = floor(getDMin() / w)*w;
  
  textAlign(CENTER);
  int highlight = -1;
  int highlightY = -1;//get the actual series that was selected at some point
  
  for(int i = 0; i < n;i++){
    //Find the bar that we will highlight with the mouse
    float x1 = toScreenX(ourDMin+i * w);
    if((mouseY > gYLoc)&&(mouseY < gYLoc + gHeight)){
      if(mouseX > x1){
        if(mouseX < toScreenX(ourDMin + i*w+w)){
          stroke(0,0,255);
          line(x1,gYLoc,x1,gYLoc + gHeight);
          line(toScreenX(ourDMin + i*w+w),gYLoc,toScreenX(ourDMin + i*w+w),gYLoc + gHeight);
          highlight = i;
          stroke(0);
          //Find the series
        }
      }
    }
    
    
    //Draw the bars
    
    float currentHeight = 0;
    int numProjInBar = 0;
    for(int j = 0; j < histFBins.length; j++){
      numProjInBar += histFBins[j][i];
    }
    
    for(int j = 0; j < histFBins.length; j++){
      //change the fill depending on the split mode.
      if(splitMode==0){
        fill(0,255,0);
      } else if (splitMode == 3){
        //Could use an array here, but not absolutely necessary cause there are only 3 things
        if(j==0){
          fill(0,255,0);
        } else if(j==1){
          fill(255,0,0);
        } else{
          fill(255);
        }
      }
      
      float value;
      if(useAverage.getState()){
        value = histFBins[j][i] / float(numProjInBar);
      } else {
        value = histFBins[j][i];
      }
      
      float y1 = toScreenY(currentHeight);
      float y2 = toScreenY(currentHeight + value);
      rect(x1, y1, toScreenX(i*w+w)-toScreenX(i*w), y2 -y1);
      currentHeight += value;
    }
    
    //Draw the axis tick for every 10th bin
    if(i%10==0){
      fill(255);
      if(ourDMin + i * w > 99999){
        if(i%2==1){
          continue;
        }
      }
      text(nfc(ourDMin + i * w,2) + measuresOfSuccessUnits[currentMeasure], x1, gYLoc + gHeight + 1.5*PADDING);
      line(x1, gYLoc + gHeight, x1, gYLoc + gHeight + 3);
    }
  }
  
  text(nfc(getDMax(),2) + measuresOfSuccessUnits[currentMeasure], toScreenX(getDMax()), gYLoc + gHeight + 1.5*PADDING);
  
  textAlign(LEFT);
  if(highlight >= 0){
    fill(155);
    rect(mouseX - 5, mouseY - 15, 250, 55); 
    fill(0,0,0);
    String a = nfc(ourDMin + highlight * w,2) + measuresOfSuccessUnits[currentMeasure];
    String b = nfc(ourDMin + highlight * w + w,2) + measuresOfSuccessUnits[currentMeasure];
    //text("interval ["+a+", "+b+") \n    = " + histFBins[0][highlight] ,mouseX,mouseY);
    text("interval ["+a+", "+b+")",mouseX+10,mouseY);
    float yPos = mouseY + 10;
    for(int i = 0; i < histFBins.length; i++){
      if(splitMode == 3){
        if(i==0){
          fill(0,255,0);
        } else if(i==1){
          fill(255,0,0);
        } else{
          fill(255);
        }
      }
      text(nfc(histFBins[i][highlight]), mouseX + 10, yPos);
      yPos += 12;
    }
  }
  
  fill(0,125);
  text("<= " + lClip + " project(s) not visible", gXLoc, gYLoc + gHeight + 3.5 * PADDING);
  textAlign(RIGHT);
  text(rClip + " project(s) not visible =>", gXLoc + gWidth, gYLoc + gHeight + 3.5 * PADDING);
  
  //We also draw the XAxis tags here based on the series ofc
  fill(255);
  text(measuresOfSuccess[currentMeasure], gXLoc + gWidth/2, gYLoc + gHeight + 3.5*PADDING);
}


void drawLegend(float x, float y){
  //have different legends for different split modes
  float lWidth = 100;
  if(splitMode==3){
    fill(0,62);
    rect(x,y, lWidth, 100);
    fill(0,255,0);
    rect(x + PADDING, y + PADDING, 15,15);
    textAlign(LEFT);
    text("Successful projects", x + PADDING + 20, y + PADDING + 15);
    
  }
}

void drawGraphBackground(){
  fill(160);
  rect(gXLoc, gYLoc, gWidth, gHeight);

  fill(255);


}

void zoomGraph(float Amount){
  float centreX = toGraphX(mouseX);
  float centreY = toGraphY(mouseY);
  setDMax(getDMin() + Amount*(getDMax()-getDMin()));
  setRMax(getRMin() + Amount*(getRMax()-getRMin()));
  float newCentreX = toGraphX(mouseX);
  float newCentreY = toGraphY(mouseY);
  translateGraph(-newCentreX+centreX, -newCentreY+centreY,false);
  recalc = true;
}

void exitHelp(){
  visualisationNumber = prevVisualisation;
  visPresets[currentMeasure].set(initVisPresets[currentMeasure]);
  recalc = true;
}

int helpWidth;
int helpHeight;

int clamp(int i, int a, int b){
  if(i < a){
    i = a;
  } else if (i > b){
    i = b;
  }
  return i;
}

void drawHelp(){  
  setDMin(clamp(round(getDMin()), 0, round(helpImg.width-gWidth)));
  int imgX = round(getDMin());
  setRMin(clamp(round(getRMin()), 0, round(helpImg.height-gHeight)));
  int imgY = round(getRMin());
  int imgW = round(gWidth);
  setDMax(getDMin() + gWidth);
  int imgH = round(gHeight);
  setRMax(getRMin() + gHeight);
  
  image(helpImg.get(imgX, imgY, imgW, imgH),gXLoc,gYLoc);
  
  float ehX = gXLoc + PADDING;
  float ehY = gYLoc + PADDING;
  float ehw = 50;
  float ehh = 20;
  if(mouseOver(ehX, ehY, ehw, ehh)){
    fill(0,255,0);
    if(mousePressed){
      exitHelp();
    }
  } else {
    fill(255,0,0);
  }
  
  rect(ehX, ehY, ehw, ehh);
  fill(255);
  textAlign(CENTER);
  text("Exit help", ehX + ehw/2, ehY + ehh/2 + 5);
}

void translateGraph(float dx, float dy, boolean convertToGraphSpace){
  if(convertToGraphSpace){
    dx = (dx / gWidth)*(getDMax()-getDMin());
    dy = (dy / gHeight)*(getRMax()-getRMin());
  }
  setDMin(getDMin()+dx);
  setDMax(getDMax()+dx);
  setRMin(getRMin()+dy);
  setRMax(getRMax()+dy);
  recalc = true;
}

void displayCategoryInfo(int i){
  float spacing = 15;
  fill(180);
  float x2 = gXLoc + PADDING;
  float y2 = gYLoc + PADDING;
  float w2 = 200;
  float h2 = 400;
  rect(gXLoc, gYLoc, gWidth,195);
  
  fill(0);
  //textAlign(CENTER);
  textSize(20);
  text(csv.getString(i, "name"), x2, y2+spacing);
  textSize(12);
  textAlign(LEFT);
  y2 += spacing*2;
  text("Project ID: " + csv.getString(i, "ID"), x2, y2);
  y2 += spacing;
  text("Country: " + csv.getString(i, "country"), x2, y2);
  y2 += spacing;
  text("Category: " + csv.getString(i, "main_category"), x2, y2);
  y2 += spacing;
  text("Sub-Category: " + csv.getString(i, "category"), x2, y2);
  y2 += spacing;
  text("Funding Goal in USD: " + nfc(csv.getFloat(i, "usd_goal_real"),2), x2, y2);
  y2 += spacing;
  text("Amount pledged in USD: " + nfc(csv.getFloat(i, "usd_pledged_real"),2), x2, y2);
  y2 += spacing;
  text("% Funded: " + nfc(csv.getFloat(i, "%funded"),2), x2, y2);
  y2 += spacing;
  text("Number of backers: " + nfc(csv.getInt(i, "backers")), x2, y2);
  y2 += spacing;
  text("Campaign in days: " + nfc(csv.getFloat(i, "duration(Days)"),4), x2, y2);
  y2 += spacing;
  text("Date launced: " + csv.getString(i, "launched"), x2, y2);
  y2 += spacing;
  text("State: " + csv.getString(i, "state"), x2, y2);
  y2 += spacing;
  fill(255);
}

boolean recalc = true;
float mousePosX=0, mousePosY=0;
boolean overAccordion = false;
int visualisationNumber = 1;
int prevVisualisation = 1;

void drawLeftSidebar(){
  float xPos = PADDING + 5;
  float yPos = 4*PADDING;
  float mWidth = 117;
  float mHeight = height - 5*PADDING;
  //fill(125);
  //rect(xPos, yPos, mWidth, mHeight);
  float currentY = yPos + PADDING;
  textAlign(LEFT);
  fill(255);
  
  float spacing = 15;
  yPos += spacing * 2;
  if(splitMode == 3){
    text("Number of projects:", xPos, yPos);
    yPos += spacing;
    fill(0);
    int sum = 0;
    for(int i : numProj){
      sum+=i;
    }
    text("  Total: "+sum, xPos, yPos);
    yPos += spacing;
    fill(255);
    text("  Inconclusive: "+numProj[2], xPos, yPos);
    yPos += spacing;
    fill(255,0,0);
    text("  Failed: "+numProj[1], xPos, yPos);
    yPos += spacing;
    fill(0,255,0);
    text("  Successful: "+numProj[0], xPos, yPos);
    yPos += spacing + 5;
    fill(255);
    
    text("Mean " + measuresOfSuccessAKA[currentMeasure] + ":", xPos, yPos);
    yPos += spacing;
    fill(0);
    text("  Total: "+nfc(totals[0]/float(sum),2), xPos, yPos);
    yPos += spacing;
    fill(255);
    text("  Inconclusive: "+nfc(totals[3]/numProj[2],2), xPos, yPos);
    yPos += spacing;
    fill(255,0,0);
    text("  Failed: "+nfc(totals[2]/numProj[1],2), xPos, yPos);
    yPos += spacing;
    fill(0,255,0);
    text("  Successful: "+nfc(totals[1]/numProj[0],2), xPos, yPos);
    yPos += spacing + 5;
    fill(255);
  }  
  
  textSize(15);
  text("Top 10:", xPos, yPos);
  textSize(12);
  yPos += spacing + 10;
  for(int i = 0; i<top10.length;i++){
    if(top10[i] < 0)
      break;
      
    float rX = xPos - 5, rY = yPos - spacing + 2.5, rW = mWidth + 10, rH = spacing;
    noFill();
    if(mouseOver(rX, rY, rW, rH)){
      displayCategoryInfo(top10[i]);
    }
    rect(rX, rY, rW, rH);
      
    fill(0);
    text(csv.getString(top10[i], measuresOfSuccess[currentMeasure]) + measuresOfSuccessUnits[currentMeasure],xPos, yPos);
    yPos += spacing;
  }
  yPos += spacing + 10;
  fill(255);
  textSize(15);
  text("Bottom 10:", xPos, yPos);
  textSize(12);
  yPos += spacing * 2;
  for(int i = 0; i<bottom10.length;i++){
    if(bottom10[i] < 0)
      continue;
      
    float rX = xPos - 5, rY = yPos - spacing + 2.5, rW = mWidth + 10, rH = spacing;
    noFill();
    if(mouseOver(rX, rY, rW, rH)){
      displayCategoryInfo(bottom10[i]);
    }
    rect(rX, rY, rW, rH);
      
    fill(0);
    text(csv.getString(bottom10[i], measuresOfSuccess[currentMeasure])+measuresOfSuccessUnits[currentMeasure], xPos, yPos);
    yPos += spacing;
  }
}

void draw(){
  background(125);
  drawGraphBackground();
  
  if(mouseOver(gXLoc + gWidth + PADDING,gYLoc,categorySidebar.getWidth(), gHeight)){
    overAccordion = true;
  } else {
    if(overAccordion){
      overAccordion = false;
      categorySidebar.close();
    }
  }
  
  float mouseDeltaX = mouseX - mousePosX;
  float mouseDeltaY = mouseY - mousePosY;
  if(dragg){
    translateGraph(-mouseDeltaX, -mouseDeltaY,true);
  }
  
  if(visualisationNumber == 0){
    drawHelp();
  } else if (visualisationNumber == 1){
    drawHistogram();
  } else if (visualisationNumber == 2){
  }
  drawLeftSidebar();
  mousePosX = mouseX;
  mousePosY = mouseY;
}

void mouseWheel(MouseEvent event) {
  if(mouseOver(gXLoc, gYLoc, gWidth, gHeight)){
    float e = event.getCount();
    if(e > 0.1f){
      zoomGraph(2);
    } else if(e < -0.1f){
      zoomGraph(0.5);
    }
  }
}

boolean dragg = false;
void mousePressed(){
  if(mouseOver(gXLoc, gYLoc, gWidth, gHeight)){
    dragg = true;
  } else {
    dragg = false;
  }
}

void mouseReleased(){
  dragg = false;
}
