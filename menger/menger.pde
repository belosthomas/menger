/*****

TODO : 
 1. Flow unitaire
 4. Chirurgie
 5. UN CODE TOUT JOLI (Nom et commentaire) !

*****/

Curve C = new Curve();
float vertexSize = 10;    // for drawing vertices as disks
int backgroundColor = 255;
boolean make_curve = true;

static int NON_RENORMALIZE = 0;
static int A_PRIORI = 1;
static int A_POSTERIORI = 2;
static int NUM_RENORMALIZATION = 3;

static int FLOW_MENGER = 0;
static int FLOW_UNITAIRE = 1;
static int FLOW_VOISINS = 2;
static int NUM_MODE = 3;

boolean flow = false;
int flow_type = FLOW_MENGER;
int flow_renormalization = A_PRIORI;
float power = 1;

float tau = 10;       // basic time interval

int informationYOffset = 10;

void setup() {
  frameRate(25);
  size(500, 600);
  background(backgroundColor);
  fill(50);
}

void draw() {
  
  ArrayList<PVector> edgeFlow = new ArrayList<PVector>();
  
  if (flow_type == FLOW_MENGER) {
    edgeFlow = C.getMengerEdgeFlows();
  }
  
  if (flow_type == FLOW_UNITAIRE) {
    // todo
    edgeFlow = C.getMengerEdgeFlows();
  }
  
  if (flow_type == FLOW_VOISINS) {
    edgeFlow = C.getNeighborEdgeFlows();
  }
  
  ArrayList<PVector> vectorFlow = npow(edgeFlowToVectorFlow(edgeFlow),power);
  
  if (flow) {
    
    if (flow_renormalization == NON_RENORMALIZE) {
      C.vertices = C.flow(vectorFlow, tau);
    }
    
    if (flow_renormalization == A_PRIORI) {
      float oldArea = C.area();
      PVector oldCentroid = C.centroid();
      C.vertices = C.flow(vectorFlow, tau);
      float newArea = C.area();
      
      float lambda = sqrt(oldArea / newArea);
      C.vertices = C.getHomothetic(lambda);
    
      PVector newCentroid =  C.centroid();
      C.vertices = C.getTranslation(oldCentroid.sub(newCentroid));
    }
    
    if (flow_renormalization == A_POSTERIORI) {
      PVector oldCentroid = C.centroid();
      C.vertices = C.flow(vectorFlow,tau);
    
      PVector newCentroid =  C.centroid();
      C.vertices = C.getTranslation(oldCentroid.sub(newCentroid));
    }
    
  }
 
  
  background(backgroundColor);              // erases for new images
  translate(width/2, height/2);  // coordinate offset to center the originf
  C.drawCurve();
  
  informationYOffset = 10;
  
  drawInformationText("nombre de tours : "+C.turningNumber());
  drawInformationText("aire : "+C.area());
  drawInformationText("tau = " + tau + " (utiliser 'p' et 'm' pour changer)");
  drawInformationText("champ = " + typeToText(flow_type) + " (utiliser 'a' pour changer)");
  drawInformationText("renormalisation = " + renormalizationToText(flow_renormalization) + " (utiliser 'z' pour changer)");
  drawInformationText("puissance = " + power  + " (utiliser 'u' et 'j' pour changer)");
  
  C.drawEdgeFlow(edgeFlow);
  C.drawCentroid();
  
}

void drawInformationText(String str) {
  text(str, -width/2+10, height/2-informationYOffset);
  informationYOffset += 20;
}

String typeToText(int m) {
  if (m == FLOW_MENGER) return "Menger";
  if (m == FLOW_UNITAIRE) return "Unitaire";
  if (m == FLOW_VOISINS) return "Voisins";
  return "Inconnu";
}

String renormalizationToText(int m) {
  if (m == NON_RENORMALIZE) return "sans";
  if (m == A_PRIORI) return "a priori";
  if (m == A_POSTERIORI) return "a posteriori";
  return "Inconnu";
}

void mouseClicked() {
  PVector point = new PVector();
  if (make_curve) {
    point.set(mouseX - width / 2, mouseY - height / 2); // coordinate offset to center the origin
    C.addVertex(point);
  }
}  

void keyReleased() {
  if (key == 'c') {
    if (make_curve && C.vertices.size() >= 3) {  // we close the loop
      C.closed = true;
    } else {  // we start a new loop
      background(100);
      C.vertices.clear();
      C.closed = false;
    }
    make_curve = !make_curve;
  }
  if (key == 's') {
    saveFrame();
  }
 
  if (key == 'f') {
    flow = !flow;
  }
  
  if (key == 'a') {
    flow_type = (flow_type + 1) % NUM_MODE;
  }
  
  if (key == 'z') {
    flow_renormalization = (flow_renormalization + 1) % NUM_RENORMALIZATION;
  }
  
  if (key == 'p') tau *= 2;
  
  if (key == 'm') tau *= 0.5;
  
  if (key == 'u'){
   if (power >= 1) power +=1;
   else power = 1/(1/power - 1);
  }
  
  if (key == 'j'){
   if (power > 1) power -= 1;
   else power = 1/(1/power + 1);
  }
  
}

////// CLASSES  ////////

class Curve {
  ArrayList<PVector> vertices = new ArrayList<PVector>();
  boolean closed;    // true if the curve is closed

  void addVertex(PVector p) {
    vertices.add(p);
  }

  void drawCurve() {
    int n = vertices.size();
    PVector current, next;
    stroke(0, 0, 0);
    // draw lines first
    for (int i=0; i < n-1; i++) {
      current = vertices.get(i);
      next = vertices.get(i+1);
      line(current.x, current.y, next.x, next.y);
    }
    if (closed) {
      current = vertices.get(n-1);
      next = vertices.get(0);
      line(current.x, current.y, next.x, next.y);
    }

    // now draw vertices
    for (int i=0; i < n; i++) {
      current = vertices.get(i);
      ellipse(current.x, current.y, vertexSize, vertexSize);
    }
  }
  
  int size() {
    return vertices.size();
  }

  float area() {
    int n = vertices.size();
    float a = 0;
    for (int i=0; i<n; i++) { 
      PVector e1 = C.vertices.get(i).copy();    // so that the i-th vertex is not modified
      a += -e1.cross(C.vertices.get((i+1)%n)).z; // vertical part of the cross product
      // minus sign because the screen in inverted in Processing
    }
    return(a/2);
  }
  
  int turningNumber() {
    int n = vertices.size();
    float totalAngle = 0;
    PVector v1,v2;
    for (int i=0; i<n; i++) {
      v1 = PVector.sub(vertices.get((i+n-1)%n),vertices.get(i));
      v2 = PVector.sub(vertices.get(i),vertices.get((i+1)%n));
      totalAngle += arcAngle(v1,v2);
    }
  return(-round(totalAngle/TWO_PI+0)); // inverted to compensate for screen symmetry
  }

  PVector centroid() {
    if (vertices.size() == 0) {
      return new PVector(0, 0);
    }
    float x = 0, y = 0;
    for (int i = 0; i < vertices.size(); i++) {
      x += vertices.get(i).x;
      y += vertices.get(i).y;
    }
    return new PVector(x / vertices.size(), y / vertices.size());
  }
  
  void drawCentroid() {
    stroke(0, 200, 0);
    PVector current = centroid();
    ellipse(current.x, current.y, vertexSize, vertexSize); 
  }
  
  ArrayList<PVector> getHomothetic(float r) {
    PVector c = centroid();
    
    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < vertices.size(); i++) {
      PVector v = vertices.get(i).copy();
      vectors.add(new PVector(r * (v.x - c.x) + c.x, r * (v.y - c.y) + c.y));
    }
    return vectors;
  }
  
  ArrayList<PVector> getTranslation(PVector t) {    
    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < vertices.size(); i++) {
      PVector v = vertices.get(i).copy().add(t);
      vectors.add(v);
    }
    return vectors;
  }
  
  
  PVector getMengerEdgeFlow(int i) { // Rend le vecteur courbure de Menger en l'arrete (i,i+1)
    if(C.vertices.size() == 2) return new PVector(0,0);
    PVector v = vertices.get((i) % vertices.size());
    PVector p = vertices.get((i + 1) % vertices.size());
    
    PVector vm = vertices.get((i - 1 + vertices.size()) % vertices.size());
    PVector pm = vertices.get((i + 2) % vertices.size());
    
    // On traite le cas des "zig-zag"
    if (determinant(v.copy().sub(vm), p.copy().sub(v)) * determinant(p.copy().sub(v), pm.copy().sub(p)) < 0) {
      return new PVector(0,0);
    }
    
    PVector v2 = midAngle(v.copy(), p.copy(), vm.copy());
    PVector p2 = midAngle(p.copy(), v.copy(), pm.copy());
    
    PVector intersection = intersection(v.copy(), v2.copy(), p.copy(), p2.copy());
    if (intersection == null) return null;
    
    PVector d = v.copy().sub(p); // d est un vecteur directeur linéaire de l'arrête
    PVector n = new PVector(-d.y, d.x); // n est un vecteur normal à d
    n.div(n.mag());
    float r = abs(intersection.sub(v).dot(n));
    
    n.mult(1 / r);
    
    // On s'assure que le vecteur est orienté dans le bon sens
    if (n.dot(vm.copy().sub(v)) < 0) n.mult(-1);
    
    return n;
    
  }

  ArrayList<PVector> getMengerEdgeFlows() {
    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < vertices.size(); i++) {
      vectors.add(getMengerEdgeFlow(i));
    }
    return vectors;
  }
  
  PVector getNeighborEdgeFlow(int i) {
    PVector v = vertices.get((i) % vertices.size());
    PVector p = vertices.get((i + 1) % vertices.size());
    
    PVector vm = vertices.get((i - 1 + vertices.size()) % vertices.size());
    PVector pm = vertices.get((i + 2) % vertices.size());
    
    return vm.copy().add(pm).sub(v).sub(p);
    
  }
  
  ArrayList<PVector> getNeighborEdgeFlows() {
    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < vertices.size(); i++) {
      vectors.add(getNeighborEdgeFlow(i));
    }
    return vectors;
  }
  
  ArrayList<PVector> flow(ArrayList<PVector> f, float tau) {
    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < f.size(); i++) {
      vectors.add(f.get(i).copy().mult(tau).add(vertices.get(i)));
    }
    return vectors;
  }
  
  ArrayList<PVector> areaGradient() {  // n-vector gradient of the area, for open or closed curves
    ArrayList<PVector> gradA = new ArrayList<PVector>();
    int n = vertices.size();
    PVector e1 = new PVector();
    for (int i=0; i<n; i++) {
      if (!this.closed && (i==0 || i==n-1)) {
        if (i==0) e1 = vertices.get(1).copy();  // only the next position
        if (i==n-1) e1 = vertices.get(n-2).copy().mult(-1); // only the previous position, negative
      } else {
        e1 = vertices.get((i+1)%n).copy();
        e1.sub(vertices.get((i-1+n)%n));
      }
      e1.rotate(HALF_PI);
      e1.mult(-0.5);
      gradA.add(e1);
    }  
    return(gradA);
  }

  ArrayList<PVector> getRenormalized(ArrayList<PVector> H) {  // renormalized mean curvature
    ArrayList<PVector> gA = this.areaGradient();
    float lambda = - ndot(H, gA)/ndot(gA, gA);
    return(nsum(H, nmult(gA, lambda)));
  }

  
  void drawEdgeFlow(ArrayList<PVector> H) {
    for (int i = 0; i < vertices.size(); i++) {
      PVector v = vertices.get((i) % vertices.size());
      PVector p = vertices.get((i + 1) % vertices.size());
      
      p = p.copy().add(v).div(2);
      
      PVector h = H.get(i);
      
      if (h != null) {
        h.mult(1000);
        stroke(0, 200, 255);
        line(p.x, p.y, p.x + h.x, p.y + h.y);
      }
    }  
  }
  
}


//////// SUBROUTINES  ////////////

/**
 * Retourne un point de la bissectrice de l'angle (left, center, right).
 *
 * @param center Le sommet de l'angle.
 * @param left Un point de la première droite de l'angle.
 * @param right Un point de l'autre droite de l'angle.
 *
 * @return Un point de la bissectrice de l'angle.
 */
PVector midAngle(PVector center, PVector left, PVector right) {
  
  // Par acquis de conscience, on copie les 3 vecteurs
  center = center.copy();
  left = left.copy();
  right = right.copy();
  
  // On se place dans le cas ou le centre est zero
  left.sub(center);
  right.sub(center);
  
  // On normalize left et right
  left.div(left.mag());
  right.div(right.mag());
  
  // La somme des points est sur la bissectrice
  left.add(right);

  return center.add(left);
  
}

/**
 * Retourne le PVector de l'intersection de deux droites passant respectivemetnt par a1 et a2, et b1 et b2.
 *
 * @param a1 Un premier point appartenant à la première droite.
 * @param a2 Un deuxième point appartenant à la première droite.
 * @param b1 Un premier point appartenant à la deuxième droite.
 * @param b2 Un deuxième point appartenant à la deuxième droite.
 *
 * @return Le PVector de l'intersection des deux droites.
 */
PVector intersection(PVector a1, PVector a2, PVector b1, PVector b2) {
  
  a1.z = 1;
  a2.z = 1;
  b1.z = 1;
  b2.z = 1;
  
  // En coordonnée barycentrique, l'intersection est (a1 Λ a2) Λ (b1 Λ b2)
  PVector p = a1.cross(a2).cross(b1.cross(b2));
  
  // On vérifie par acquis de conscience que les droites ne sont pas parrallèles
  if (p.z == 0) return null;
  
  // On retourne le point obtenu
  p.div(p.z);
  return p;
}
/**
 * Retourne le determinant de la matrice définie par deux vecteurs de dimension deux.
 *
 * @param a un PVector.
 * @param b un PVector.
 *
 * @return Le determinant de a et b.
 */
float determinant(PVector a, PVector b) {
  return a.x * b.y - a.y * b.x;
}

/**
 * Transforme un champ sur les arrêtes en un champ sur les sommets
 *
 * @param edgeFlow le champ sur les arrêtes.
 * 
 * @return le champ sur les sommets
 */
ArrayList<PVector> edgeFlowToVectorFlow(ArrayList<PVector> edgeFlow) {
  ArrayList<PVector> vectorFlow = new ArrayList<PVector>();
  for(int i = 0; i< edgeFlow.size(); i++){
      PVector edgeFlow1 = edgeFlow.get(i);
      PVector edgeFlow2 = edgeFlow.get((i - 1 + edgeFlow.size()) % edgeFlow.size());
      vectorFlow.add(edgeFlow1.copy().add(edgeFlow2));
  }
  return vectorFlow;
}

/**
 * Calcule la valeur de la mesure d'un angle dans ]-pi,pi].
 *
 * @param v1 premier vecteur de l'angle.
 * @param v2 deuxième vecteur de l'angle.
 *
 * @return valeur de l'angle.
 */
float arcAngle(PVector v1, PVector v2) {
  float r = atan2(v2.y, v2.x) - atan2(v1.y, v1.x);
  if (r<-PI) {
    r += 2*PI;
  }
  if (r>PI) {
    r -= 2*PI;
  }
  return(r);
}

/**
 * Retourne le produit scalaire de deux vecteurs encodés comme des listes de PVector.
 *
 * @param U la première liste de PVector.
 * @param V la deuxième liste de PVector.
 *
 * @return La norme 1 du produit scalaire terme à terme de U et V.
 */
float ndot(ArrayList<PVector> U, ArrayList<PVector> V) {  // scalar product between n-vectors
  float s = 0;
  for (int i=0; i<min(U.size(), V.size()); i++) {
    s += PVector.dot(U.get(i), V.get(i));
  }
  return(s);
}

/**
 * Retourne la somme terme à terme de listes de PVector
 *
 * @param U La première liste de PVector.
 * @param V La deuxième liste de PVector.
 *
 * @return La somme des listes terme à terme.
 */
ArrayList<PVector> nsum(ArrayList<PVector> U, ArrayList<PVector> V) {
  ArrayList<PVector> W = new ArrayList<PVector>();
  for (int i=0; i<min(U.size(), V.size()); i++) {
    W.add(PVector.add(U.get(i), V.get(i)));
  }
  return(W);
}

/**
 * Multiplie une liste de Pvector par un scalaire.
 *
 * @param U La liste de PVector
 * @param lambda Le scalaire
 *
 * @return Le produit lambda*U
 */
ArrayList<PVector> nmult(ArrayList<PVector> U, float lambda) { 
  ArrayList<PVector> W = new ArrayList<PVector>();
  for (int i=0; i<U.size(); i++) {
    W.add(PVector.mult(U.get(i), lambda));
  }
  return(W);
}
/**
 * Mets à la puissance la norme de chaque PVector d'une liste
 *
 * @param U Une liste de PVector.
 * @param n La puissance à laquelle on veut élever les normes des vecteurs.
 *
 * @return La liste des PVector d'origine dont la norme a été mise à la puissance n.
 */
ArrayList<PVector> npow(ArrayList<PVector> U, float n) {
  ArrayList<PVector> W = new ArrayList<PVector>();
  for (int i=0; i<U.size(); i++) {
    W.add(new PVector(pow(U.get(i).x, n), pow(U.get(i).y, n), pow(U.get(i).z, n)));
  }
  return(W);
}

/**
 * divise chaque PVector d'une liste par sa norme.
 *
 * @param La liste des PVector à normaliser.
 *
 * @return La liste des PVector normalisés.
 */
ArrayList<PVector> nnorm(ArrayList<PVector> U) {
  ArrayList<PVector> W = new ArrayList<PVector>();
  for (int i=0; i<U.size(); i++) {
    W.add(U.get(i).copy().div(U.get(i).mag()));
  }
  return(W);
}
