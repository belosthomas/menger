/*****

 Géométrie différentielle discrète
 Flots de courbes discrètes 2D par les arrêtes
 
 *****
 
 Doriann Albertin
 Thomas Belos
 
 *****
 
 Comment ça fonctionne ?
 Une fois le programme lancé, cliquez sur la fenêtre pour ajouter un point à la courbe.
 Une fois la courbe tracée, appuyez sur "c" pour fermer la courbe, et sur "f" pour lancer le flot.
 Les choix du champ, de la renormalisation, de la puissance, du pas de discrétisation tau et de la puissance sont guidés à l'écran.
 Sont proposés trois champs différents et trois renormalisations, qui sont détaillés dans le pdf joint.
 
 *****/

Curve C = new Curve();
float vertexSize = 10;
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

boolean flow = false;                  // pour activation du flot
int flow_type = FLOW_MENGER;           // champ par défaut
int flow_renormalization = A_PRIORI;   // renormalisation par défaut
float power = 1;                       // puissance par défaut
float tau = 10;                        // pas de temps par défaut
float surge_threshold = 5;             // seuil de la chirurgie

int informationYOffset = 10;           // paramêtre pour affichage du texte

/**
 * La fonction d'initialisation de Processing, qui va initialiser la fenetre.
 */
void setup() {
  frameRate(25);
  size(500, 600);
  background(backgroundColor);
  fill(50);
}


void draw() {

  ArrayList<PVector> edgeFlow = new ArrayList<PVector>();

  // On récupère sous la variable edgeFlow le champ des arrêtes.
  if (flow_type == FLOW_MENGER) {
    edgeFlow = C.getMengerEdgeFlows();
  }

  if (flow_type == FLOW_UNITAIRE) {
    edgeFlow = C.getUnitFlows();
  }

  if (flow_type == FLOW_VOISINS) {
    edgeFlow = C.getNeighborEdgeFlows();
  }

  // On converti le champ en question en champ sur les sommets pour traitement.
  ArrayList<PVector> vectorFlow = npow(edgeFlowToVectorFlow(edgeFlow), power);


  // Si le flot est lancé, on calcule la courbe suivante, avec potentielle renormalisation.
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
      C.vertices = C.flow(C.getRenormalized(vectorFlow), tau);

      PVector newCentroid =  C.centroid();
      C.vertices = C.getTranslation(oldCentroid.sub(newCentroid));
    }
  }
  
  // On applique la chirurgie
  C.surge(surge_threshold);

  // Et on affiche la courbe...
  background(backgroundColor);
  translate(width/2, height/2);
  C.drawCurve();

  // ...les informations...
  informationYOffset = 10;
  //drawInformationText("nombre de tours : "+C.turningNumber());
  drawInformationText("aire : "+C.area());
  drawInformationText("tau = " + tau + " ('p' pour augmenter et 'm' pour diminuer)");
  drawInformationText("champ = " + typeToText(flow_type) + " ('a' pour changer)");
  drawInformationText("renormalisation = " + renormalizationToText(flow_renormalization) + " ('z' pour changer)");
  drawInformationText("puissance = " + power  + " ('u' pour augmenter et 'j' pour diminuer)");
  drawInformationText("seuil de chirurgie = " + surge_threshold  + " ('o' pour augmenter et 'l' pour diminuer)");

  if (C.vertices.size() == 0) {
    textAlign(CENTER);
    textSize(30);
    text("Cliquer pour créer un point", 0, 0);
    textAlign(LEFT);
    textSize(14);
  }

  // ...et le flow !
  C.drawEdgeFlow(edgeFlow);
  // if (C.vertices.size() > 1) C.drawCentroid(); // pour test
}

/**
 * Cette fonction permet d'écrire du texte empilé automatiquement.
 *
 * @param str Le texte à écrire à l'écran.
 */
void drawInformationText(String str) {
  text(str, -width/2+10, height/2-informationYOffset);
  informationYOffset += 20;
}

/**
 * Cette fonction convertie un type de flow en texte. Utile pour l'affichage.
 *
 * @param m Le type de flow
 * @return Un texte représentant le nom du flow
 */
String typeToText(int m) {
  if (m == FLOW_MENGER) return "Menger";
  if (m == FLOW_UNITAIRE) return "Unitaire";
  if (m == FLOW_VOISINS) return "Voisins";
  return "Inconnu";
}

/**
 * Cette fonction convertie un type de renormalisation en texte. Utile pour l'affichage.
 *
 * @param m Le type de renormalisation
 * @return Un texte représentant le nom de la renormalisation
 */
String renormalizationToText(int m) {
  if (m == NON_RENORMALIZE) return "sans";
  if (m == A_PRIORI) return "a priori";
  if (m == A_POSTERIORI) return "a posteriori";
  return "Inconnu";
}

/**
 * Fonction de processing appelée lors du clic de la souris.
 */
void mouseClicked() {
  PVector point = new PVector();
  if (make_curve) {
    point.set(mouseX - width / 2, mouseY - height / 2);
    C.addVertex(point);
  }
}  

/**
 * Fonction de processing appellé lorque qu'une touche est relachée.
 */
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
  
  if (key == 'o') surge_threshold *= 2;
  
  if (key == 'l') surge_threshold *= 0.5;

  if (key == 'u') {
    if (power >= 1) power +=1;
    else power = 1/(1/power - 1);
  }

  if (key == 'j') {
    if (power > 1) power -= 1;
    else power = 1/(1/power + 1);
  }
}

/**
 * Voici la classe Curve. Cette classe va contenir toutes les fonctions nécéssaires au manipulation d'une courbe.
 */
class Curve {
  ArrayList<PVector> vertices = new ArrayList<PVector>(); // La liste des vertices de la courbe
  boolean closed;    // vrai si la courbe est fermée.

  /**
   * Ajoute un vertex à la courbe.
   *
   * @param p Le vertex à ajouter.
   */
  void addVertex(PVector p) {
    vertices.add(p);
  }

  /**
   * Dessine la courbe à l'écran
   */
  void drawCurve() {
    int n = vertices.size();
    PVector current, next;
    stroke(0, 0, 0);
    // Tracé des arrêtes
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

    // tracé des sommets
    for (int i=0; i < n; i++) {
      current = vertices.get(i);
      ellipse(current.x, current.y, vertexSize, vertexSize);
    }
  }

  /**
   * Retourne le nombre de vertex de la courbe.
   * @return Le nombre de vertex de la courbe
   */
  int size() {
    return vertices.size();
  }

  /**
   * Calcul et retourne l'air de la courbe
   * @return L'air de la courbe
   */
  float area() {
    int n = vertices.size();
    float a = 0;
    for (int i=0; i<n; i++) { 
      PVector e1 = C.vertices.get(i).copy();
      a += -e1.cross(C.vertices.get((i+1)%n)).z; // vertical part of the cross product
      // minus sign because the screen in inverted in Processing
    }
    return(a/2);
  }

  /**
   * Calcul et retourne le turning number de la courbe
   * @return Le turning number de la courbe
   */
  int turningNumber() {
    int n = vertices.size();
    float totalAngle = 0;
    PVector v1, v2;
    for (int i=0; i<n; i++) {
      v1 = PVector.sub(vertices.get((i+n-1)%n), vertices.get(i));
      v2 = PVector.sub(vertices.get(i), vertices.get((i+1)%n));
      totalAngle += arcAngle(v1, v2);
    }
    return(-round(totalAngle/TWO_PI+0)); // opposé pour palier la symmétrie de processing
  }

  /**
   * Calcul et retourne le centroid de la courbe
   * @return Le centroid de la courbe
   */
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

  /**
   * Calcul et affiche le centroid de la courbe à l'écran
   */
  void drawCentroid() {
    stroke(0, 200, 0);
    PVector current = centroid();
    ellipse(current.x, current.y, vertexSize, vertexSize);
  }

  /**
   * Retourne une liste de vertex représentant une nouvelle courbe agrandit par un facteur de r.
   * @param r Le facteur d'agrandissement
   * @return La nouvelle courbe
   */
  ArrayList<PVector> getHomothetic(float r) {
    PVector c = centroid();

    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < vertices.size(); i++) {
      PVector v = vertices.get(i).copy();
      vectors.add(new PVector(r * (v.x - c.x) + c.x, r * (v.y - c.y) + c.y));
    }
    return vectors;
  }

  /**
   * Retourne une liste de vertex représentant une nouvelle courbe translaté par un vecteur t.
   * @param r La translation a appliqué
   * @return La nouvelle courbe
   */
  ArrayList<PVector> getTranslation(PVector t) {    
    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < vertices.size(); i++) {
      PVector v = vertices.get(i).copy().add(t);
      vectors.add(v);
    }
    return vectors;
  }

  /**
   * Retourne le flow unitaire pour l'arête entre i et i + 1.
   * @param i L'identifiant de l'arête à traiter
   * @return Le flow de l'arête entre i et i + 1
   */
  PVector getUnitFlow(int i) { // flot de norme 1, rentrant, perpendiculaire à l'arrête
    PVector current = vertices.get((i) % vertices.size());
    PVector next = vertices.get((i+1) % vertices.size());

    PVector previous = vertices.get((i - 1 + vertices.size()) % vertices.size());
    PVector after = vertices.get((i + 2) % vertices.size());

    // On traite le cas des "zig-zag"
    if (determinant(current.copy().sub(previous), next.copy().sub(current)) * determinant(next.copy().sub(current), after.copy().sub(next)) < 0) {
      return new PVector(0, 0);
    }

    PVector d = current.copy().sub(next); // d est un vecteur directeur de l'arrête.
    PVector n = new PVector(-d.y, d.x); // n est un vecteur normal à l'arrête.
    n = n.div(n.mag());
    // n est unitaire normal, mais il s'agit encore de fixer son orientation
    if (n.dot(previous.copy().sub(current)) < 0) n.mult(-1);
    return n;
  }
  
  /**
   * @return le flow unitaire pour toutes les arêtes
   */
  ArrayList<PVector> getUnitFlows(){
    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < vertices.size(); i++) {
      vectors.add(getUnitFlow(i));
    }
    return vectors;
  }

  /**
   * Retourne le flow de menger pour l'arête entre i et i + 1.
   * @param i L'identifiant de l'arête à traiter
   * @return Le flow de l'arête entre i et i + 1
   */
  PVector getMengerEdgeFlow(int i) { // Rend le vecteur courbure de Menger en l'arrete (i,i+1)
    PVector current = vertices.get((i) % vertices.size());
    PVector next = vertices.get((i + 1) % vertices.size());

    PVector previous = vertices.get((i - 1 + vertices.size()) % vertices.size());
    PVector after = vertices.get((i + 2) % vertices.size());

    if (determinant(current.copy().sub(previous), next.copy().sub(current)) * determinant(next.copy().sub(current), after.copy().sub(next)) < 0) {
      return new PVector(0, 0);
    }

    PVector v2 = midAngle(current.copy(), next.copy(), previous.copy());
    PVector p2 = midAngle(next.copy(), current.copy(), after.copy());

    PVector intersection = intersection(current.copy(), v2.copy(), next.copy(), p2.copy());
    if (intersection == null) return new PVector(0, 0);

    PVector d = current.copy().sub(next); // d est un vecteur directeur linéaire de l'arrête
    PVector n = new PVector(-d.y, d.x); // n est un vecteur normal à d
    n.div(n.mag());
    float r = abs(intersection.sub(current).dot(n));

    n.mult(1 / r);

    // On s'assure que le vecteur est orienté dans le bon sens
    if (n.dot(previous.copy().sub(current)) < 0) n.mult(-1);

    return n;
  }

  /**
   * @return le flow de menger pour toutes les arêtes
   */
  ArrayList<PVector> getMengerEdgeFlows() {
    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < vertices.size(); i++) {
      vectors.add(getMengerEdgeFlow(i));
    }
    return vectors;
  }

  /**
   * Retourne le flow "neighbor" pour l'arête entre i et i + 1.
   * @param i L'identifiant de l'arête à traiter
   * @return Le flow de l'arête entre i et i + 1
   */
  PVector getNeighborEdgeFlow(int i) {
    PVector current = vertices.get((i) % vertices.size());
    PVector next = vertices.get((i + 1) % vertices.size());

    PVector previous = vertices.get((i - 1 + vertices.size()) % vertices.size());
    PVector after = vertices.get((i + 2) % vertices.size());

    return previous.copy().add(after).sub(current).sub(next);
  }

  /**
   * @return le flow "neighbor" pour toutes les arêtes
   */
  ArrayList<PVector> getNeighborEdgeFlows() {
    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < vertices.size(); i++) {
      vectors.add(getNeighborEdgeFlow(i));
    }
    return vectors;
  }

  /**
   * Applique le flow à tous les vertex, et retourne les nouveaux vertex.
   * @param f Le flow à appliquer
   * @param tau Le facteur de temps
   * @return Les nouveaux vertex
   */
  ArrayList<PVector> flow(ArrayList<PVector> f, float tau) {
    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < f.size(); i++) {
      vectors.add(f.get(i).copy().mult(tau).add(vertices.get(i)));
    }
    return vectors;
  }

  /**
   * Calcul le gradient de l'air dans l'espace des courbes
   * @return Le gradient de l'air
   */
  ArrayList<PVector> areaGradient() {
    ArrayList<PVector> gradA = new ArrayList<PVector>();
    int n = vertices.size();
    PVector e1 = new PVector();
    for (int i=0; i<n; i++) {
      if (!this.closed && (i==0 || i==n-1)) { // traitement des courbes ouvertes.
        if (i==0) e1 = vertices.get(1).copy();
        if (i==n-1) e1 = vertices.get(n-2).copy().mult(-1);
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

  /**
   * Projette un champ sur l'orthogonal du gradient de l'aire, pour préserver celle-ci
   * @return Le flow renormalisé
   */
  ArrayList<PVector> getRenormalized(ArrayList<PVector> H) {
    ArrayList<PVector> gA = this.areaGradient();
    float lambda = - ndot(H, gA)/ndot(gA, gA);
    return(nsum(H, nmult(gA, lambda)));
  }

  /**
   * Affiche le flow H de chaques arêtes
   * @param H Le flow à afficher
   */
  void drawEdgeFlow(ArrayList<PVector> H) {
    
    float normAverage = 0;
    for (int i = 0; i < H.size(); i++) {
      normAverage += H.get(i).mag();
    }
    normAverage /= (float)H.size();
    
    // System.out.println("Norm average : " + normAverage); // pour test
    
    for (int i = 0; i < vertices.size(); i++) {
      PVector v = vertices.get((i) % vertices.size());
      PVector p = vertices.get((i + 1) % vertices.size());

      p = p.copy().add(v).div(2);

      PVector h = H.get(i).copy();

      if (h != null) {
        h.mult(32.0 / normAverage);
        stroke(0, 200, 255);
        line(p.x, p.y, p.x + h.x, p.y + h.y);
      }
    }
  }
  
  /**
   * Vérifie si il est possible de faire de la chirurgie pour les vertices i et i+1, et la fait si c'est possible.
   * La chirurgie va fusionner deux vertices si ils sont à une distance inférieur à threshold.
   * @param i L'identifiant du vertex
   * @param threshold Le threshold de la chirurgie
   */
  void surgeCheckAndMerge(int i, float threshold) {
    PVector current = vertices.get((i) % vertices.size());
    PVector next = vertices.get((i + 1) % vertices.size());
    
    if (current.copy().sub(next).mag() < threshold) {
      current.add(next).div(2);
      vertices.remove(next);
    }
    
  }
  
  /**
   * Vérifie et tente d'appliquer la chirurgie sur tout les vertices.
   */
  void surge(float threshold) {
    if (vertices.size() <= 1) return;
    for (int i = 0; i < vertices.size(); i++) {
      surgeCheckAndMerge(i, threshold);
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
  for (int i = 0; i< edgeFlow.size(); i++) {
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
