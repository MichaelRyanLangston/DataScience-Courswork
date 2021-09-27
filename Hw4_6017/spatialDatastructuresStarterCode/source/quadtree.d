import common;

struct QuadTree{

    //alias of common data types
    alias P2 = Point!2;
    alias Box = AABB!2;

    //Internal Class 
    class Node{
        //Node Member Vars
        bool aLeaf = false;
        P2[] listOfPoints;
        Box areaCovered;
        Node[4] children;

        //Constructor
        this(P2[] passedInListOfPoints, Box previousBoundingBox){
            //Determine if the node is internal or a leaf and assign field values based on this condittion.
            if(passedInListOfPoints.length <= 64){
                assert(passedInListOfPoints.length <= 64);
                aLeaf = true;
                listOfPoints = passedInListOfPoints;
                areaCovered = previousBoundingBox;
            }
            else{
                //Partition points into 4 spaces
                // NW | NE           0   1   2   3
                // -------     =>  [NW, SW, NE, SE]
                // SW | SE
                
                //(AABB max + min / 2) for only 2 dimentions of the quad tree
                // writeln(passedInListOfPoints.length);
                areaCovered = previousBoundingBox;
                float sp0 = (areaCovered.max[0] + areaCovered.min[0]) / 2.0;
                float sp1 = (areaCovered.max[1] + areaCovered.min[1]) / 2.0; 

                //calculate the splits
                P2[] east = passedInListOfPoints.partitionByDimension!0(sp0);
                P2[] west = passedInListOfPoints[0 .. $ - east.length];
                
                P2[] northWest = west.partitionByDimension!1(sp1);
                P2[] southWest = west[0 .. $ - northWest.length];

                P2[] northEast = east.partitionByDimension!1(sp1);
                P2[] southEast = east[0 .. $ - northEast.length];

                // writeln(text("East: ", east.length));
                // writeln(east);
                // writeln(text("West: ", west.length));
                // writeln(west);
                // writeln(text("NorthWest: ", northWest.length));
                // writeln(northWest);
                // writeln(text("SouthWest: ", southWest.length));
                // writeln(southWest);
                // writeln(text("NorthEast: ", northEast.length));
                // writeln(northEast);
                // writeln(text("SouthEast: ", southEast.length));
                // writeln(southEast);


                // recursively create children
                children[0] = new Node(northWest, boundingBox!2(northWest));
                children[1] = new Node(southWest, boundingBox!2(southWest));
                children[2] = new Node(northEast, boundingBox!2(northEast));
                children[3] = new Node(southEast, boundingBox!2(southEast));
            }
        }
    }

    //Struct Variables
    Node root;

    //Struct Constructor
    this(P2[] pointSoup){
        root = new Node(pointSoup, boundingBox!2(pointSoup));
    }

    //Query Functions
    P2[] rangeQuery(P2 quereyPoint, float radius){
        P2[] ret;
        void recurse(Node n){
            if(n.aLeaf){
                //iterate through each point and check to see if its with the radius
                foreach(point; n.listOfPoints){
                    if(distance(quereyPoint, point) <= radius){
                        ret ~= point;
                    }
                }
            }
            else{
                //for each child, check to see if the boudingbox and radius intersect via the closest function
                foreach(child; n.children){
                    P2 closestPoint = closest!2(child.areaCovered, quereyPoint);
                    if(distance(quereyPoint, closestPoint) <= radius){
                        recurse(child);
                    }
                }
            }
        }
        recurse(root);
        return ret;
    }

    P2[] KNNQuery(P2 quereyPoint, int k){
        auto ret = makePriorityQueue(quereyPoint);
        if(k == 0){
            return ret.release;
        }
        void recurse(Node n){
            if(n.aLeaf){
                foreach(point; n.listOfPoints){
                    //if the queue isn't full add points to it other wise commpare the point with the worst point in the queue and replace it if needed
                    if(ret.length < k){
                        ret.insert(point);
                    }
                    else if(distance(quereyPoint, point) < distance(quereyPoint, ret.front)){
                        ret.removeFront;
                        ret.insert(point);
                    }
                }
            }
            else{
                foreach(child; n.children){
                    P2 closestPoint = closest!2(child.areaCovered, quereyPoint);
                    if(ret.length < k || distance(quereyPoint, closestPoint) < distance(quereyPoint, ret.front)) {
                        recurse(child);
                    }
                }
            }
        }
        recurse(root);
        return ret.release;
    }
}

unittest{
        writeln();
        writeln();
        writeln();
        writeln("Begining QuadTree testing.");
        writeln("Node Unit Testing");

        //creating a list of points
        Point!2[] testingPoints;
        for(int i = -5; i <= 5; i++){
            for(int j = -5; j <= 5; j++){
                auto point = Point!2([i,j]);
                testingPoints ~= point;
            }
        }

        //creating test points
        auto center = Point!2([0,0]);
        auto nw = Point!2([-5,5]);
        auto sw = Point!2([-5,-5]);
        auto ne = Point!2([5,5]);
        auto se = Point!2([5,-5]);

        //creating testing Tree 
        auto testQuadTree = QuadTree(testingPoints);

        //testing range querey
        writeln("RangeQueryTesting");
        auto returnCenterK = testQuadTree.rangeQuery(center, 1.0);
        writeln(returnCenterK);
        auto returnNWK = testQuadTree.rangeQuery(nw, 1.0);
        writeln(returnNWK);
        auto returnSWK = testQuadTree.rangeQuery(sw, 1.0);
        writeln(returnSWK);
        auto returnNEK = testQuadTree.rangeQuery(ne, 1.0);
        writeln(returnNEK);
        auto returnSEK = testQuadTree.rangeQuery(se, 1.0);
        writeln(returnSEK);
 
        //testing KNN querey
        writeln("KNNQueryTesting");
        auto returnCenter = testQuadTree.KNNQuery(center, 9);
        writeln(returnCenter);
        auto returnNW = testQuadTree.KNNQuery(nw, 1);
        writeln(returnNW);
        auto returnSW = testQuadTree.KNNQuery(sw, 2);
        writeln(returnSW);
        auto returnNE = testQuadTree.KNNQuery(ne, 3);
        writeln(returnNE);
        auto returnSE = testQuadTree.KNNQuery(se, 4);
        writeln(returnSE);

        writeln();
        writeln();
        writeln();
    }