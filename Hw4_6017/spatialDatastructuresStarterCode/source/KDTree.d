import common;
import std;


struct KDTree(size_t Dim){

    //alias of common data types
    alias PD = Point!Dim;
    alias Box = AABB!Dim;

    //Internal Class
    class Node(size_t splitDim){
        //Node Member Vars
        enum thisLevel = splitDim;
        enum nextLevel = (splitDim + 1) % Dim;
        Node!nextLevel left, right;
        PD medianPoint;

        //Constructor
        this(PD[] passedInListOfPoints){
            //find the median and store it
            passedInListOfPoints.medianByDimension!thisLevel;
            int medianIndex = cast(int)(passedInListOfPoints.length / 2);
            medianPoint = passedInListOfPoints[medianIndex];

            //make the left and right lists excluding the median point
            auto leftList = passedInListOfPoints[0..medianIndex];
            auto rightList = passedInListOfPoints[(medianIndex + 1)..passedInListOfPoints.length];

            //check if the lists are empty and recurse if needed.
            if(leftList.length != 0){
                left = new Node!nextLevel(leftList);
            }
            else{
                left = null;
            }
            if(rightList.length != 0){
                right = new Node!nextLevel(rightList);
            }
            else{
                right = null;
            }
        }
    }

    //Struct Member Vars
    Node!0 root;

    //Struct Constructor
    this(PD[] pointSoup){
        root = new Node!0(pointSoup);
    }

    //rangeQuerey
    PD[] rangeQuery(PD quereyPoint, float radius){
        PD[] ret;
        void recurse(NodeType)(NodeType n){
            if(distance(quereyPoint, n.medianPoint) <= radius){
                ret ~= n.medianPoint;
            }
            if((quereyPoint[n.thisLevel] - radius) <= n.medianPoint[n.thisLevel]){
                if(n.left !is null){
                    recurse(n.left);
                }
            }
            if((quereyPoint[n.thisLevel] + radius) >= n.medianPoint[n.thisLevel]){
                if(n.right !is null){
                    recurse(n.right);
                }
            }
        }
        recurse(root);
        return ret;
    }

    //KNNQuerey
    PD[] KNNQuery(PD quereyPoint, int k){

        //make priority queue and check if k is 0
        auto ret = makePriorityQueue(quereyPoint);
        if(k == 0){
            return ret.release;
        }

        //inner function
        void recurse(NodeType)(NodeType n, Box bounds){

            //Check the point and insert it if needed
            if(ret.length < k){
                ret.insert(n.medianPoint);
            }
            else if(distance(quereyPoint, n.medianPoint) < distance(quereyPoint, ret.front)){
                ret.removeFront;
                ret.insert(n.medianPoint);
            }

            //create the bounding boxes for the left and right children and find the closest point in each of them
            Box AABBLeft = bounds;
            AABBLeft.max[n.thisLevel] = n.medianPoint[n.thisLevel];
            PD closestPointLeft = closest(AABBLeft, quereyPoint);
            // writeln("Left AABB");
            // writeln(AABBLeft.max);
            // writeln(AABBLeft.min);
            // writeln(closestPointLeft);

            Box AABBRight = bounds;
            AABBRight.min[n.thisLevel] = n.medianPoint[n.thisLevel];
            auto closestPointRight = closest(AABBRight, quereyPoint);
            // writeln("Right AABB");
            // writeln(AABBRight.max);
            // writeln(AABBRight.min);
            // writeln(closestPointRight);
            
            //check the left and right to see if recursion is needed
            if(ret.length < k || distance(quereyPoint, closestPointLeft) < distance(quereyPoint, ret.front)){
                if(n.left !is null){
                    recurse(n.left, AABBLeft);
                }
            }
            if(ret.length < k || distance(quereyPoint, closestPointRight) < distance(quereyPoint, ret.front)){
                if(n.right !is null){
                    recurse(n.right, AABBRight);
                }
            }
        }

        //create an infinite bounding box and pass it into the recurse function
        Box infiniteBox;
        foreach(i; 0..Dim){
            infiniteBox.max[i] = float.infinity;
            infiniteBox.min[i] = -float.infinity;
        }
        recurse(root, infiniteBox);
        return ret.release;
    }
}

unittest{
    writeln();
    writeln();
    writeln();
    writeln("KDTree Testing");

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
        writeln("Node Testing");
        auto dim2KDTree = KDTree!2(testingPoints);

        //testing range querey
        writeln("RangeQueryTesting");
        auto returnCenterK = dim2KDTree.rangeQuery(center, 1.0);
        writeln(returnCenterK);
        auto returnNWK = dim2KDTree.rangeQuery(nw, 1.0);
        writeln(returnNWK);
        auto returnSWK = dim2KDTree.rangeQuery(sw, 1.0);
        writeln(returnSWK);
        auto returnNEK = dim2KDTree.rangeQuery(ne, 1.0);
        writeln(returnNEK);
        auto returnSEK = dim2KDTree.rangeQuery(se, 1.0);
        writeln(returnSEK);

        //testing KNN querey
        writeln("KNNQueryTesting");
        auto returnCenter = dim2KDTree.KNNQuery(center, 9);
        writeln(returnCenter);
        auto returnNW = dim2KDTree.KNNQuery(nw, 1);
        writeln(returnNW);
        auto returnSW = dim2KDTree.KNNQuery(sw, 2);
        writeln(returnSW);
        auto returnNE = dim2KDTree.KNNQuery(ne, 3);
        writeln(returnNE);
        auto returnSE = dim2KDTree.KNNQuery(se, 4);
        writeln(returnSE);

    writeln();
    writeln();
    writeln();
}