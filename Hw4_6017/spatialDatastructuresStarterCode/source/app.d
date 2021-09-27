module app;

import std.stdio;
import std.file;


import common;
import dumbknn;
import bucketknn;
//import your files here
import KDTree;
import quadtree;
//source for file IO
// https://www.youtube.com/watch?v=rwZFTnf9bDU

void main()
{

    //because dim is a "compile time parameter" we have to use "static foreach"
    //to loop through all the dimensions we want to test.
    //the {{ are necessary because this block basically gets copy/pasted with
    //dim filled in with 1, 2, 3, ... 7.  The second set of { lets us reuse
    //variable names.

    //fixed k, N, variable D
    writeln("dumbKNN results");
    File myfile = File("dumbKNNVaried_D.csv", "w");
    myfile.writeln("k,N,D,Time(us)");
    static foreach(dim; 1..11){{
        //get points of the appropriate dimension
        int k = 10;
        int N = 1000;
        auto trainingPoints = getGaussianPoints!dim(N);
        auto testingPoints = getUniformPoints!dim(100);
        auto kd = DumbKNN!dim(trainingPoints);
        writeln("tree of dimension ", dim, " built");
        myfile.write(k,",",N,",",dim,",");
        auto sw = StopWatch(AutoStart.no);
        sw.start; //start my stopwatch
        foreach(const ref qp; testingPoints){
            kd.knnQuery(qp, k);
        }
        sw.stop;
        myfile.writeln(sw.peek.total!"usecs");
        writeln(sw.peek.total!"usecs"); //output the time elapsed in microseconds
        //NOTE, I SOMETIMES GOT TOTALLY BOGUS TIMES WHEN TESTING WITH DMD
        //WHEN YOU TEST WITH LDC, YOU SHOULD GET ACCURATE TIMING INFO...
        
    }}
    myfile.close();

    
    //fixed k, N, variable D
    writeln("BucketKNN results");
    //Same tests for the BucketKNN
    File myfile2 = File("BucketKNNVaried_D.csv", "w");
    myfile2.writeln("k,N,D,Time(us)");
    static foreach(dim; 1..11){{
        //get points of the appropriate dimension
        int k = 10;
        int N = 1000;
        enum numTrainingPoints = 1000;
        auto trainingPoints = getGaussianPoints!dim(N);
        auto testingPoints = getUniformPoints!dim(100);
        auto kd = BucketKNN!dim(trainingPoints, cast(int)pow(numTrainingPoints/64, 1.0/dim)); //rough estimate to get 64 points per cell on average
        writeln("tree of dimension ", dim, " built");
        myfile2.write(k,",",N,",",dim,",");
        
        auto sw = StopWatch(AutoStart.no);
        sw.start; //start my stopwatch
        foreach(const ref qp; testingPoints){
            kd.knnQuery(qp, k);
        }
        sw.stop;
        myfile2.writeln(sw.peek.total!"usecs");
        writeln(sw.peek.total!"usecs"); //output the time elapsed in microseconds
        //NOTE, I SOMETIMES GOT TOTALLY BOGUS TIMES WHEN TESTING WITH DMD
        //WHEN YOU TEST WITH LDC, YOU SHOULD GET ACCURATE TIMING INFO...
    }}
    myfile2.close();

    //This code was used to test both kd and quad trees by switching out minor bits of code namely auto testTree and file name
    File file3 = File("QuadTreeKNNConstD_2.csv", "w");{
        file3.writeln("k,N,D,Time(us)");
        const int D = 2;
        foreach (k; 0..11){
            foreach (N; [1, 50, 100, 200, 400, 800, 1600, 3200, 6400, 12800]){
                file3.write(k,",",N,",",D,",");
                ulong sum = 0;
                foreach (round; 0..3)
                {
                    auto trainingPoints = getGaussianPoints!D(N);
                    auto testingPoints = getUniformPoints!D(100);
                    auto testTree = QuadTree(trainingPoints);
                    auto sw = StopWatch(AutoStart.no);
                    sw.start; //start my stopwatch
                    foreach(const ref qp; testingPoints){
                        testTree.KNNQuery(qp, k);
                    }
                    sw.stop;
                    sum += sw.peek.total!"usecs";
                }
                file3.writeln(cast(int)(sum/3));
            }
        }
        file3.close();
    }

    //fixed k, N variable D
    File file4 = File("KDTreeKNNVaried_D.csv", "w");{
        file4.writeln("Const_k,Const_N,D,Time(us)");
        const int k = 10;
        const int N = 1000;
        static foreach (D; 1..11){{
           file4.write(k,",",N,",",D,",");
                ulong sum = 0;
                foreach (round; 0..3)
                {
                    auto trainingPoints = getGaussianPoints!D(N);
                    auto testingPoints = getUniformPoints!D(100);
                    auto testTree = KDTree.KDTree!D(trainingPoints);
                    auto sw = StopWatch(AutoStart.no);
                    sw.start; //start my stopwatch
                    foreach(const ref qp; testingPoints){
                        testTree.KNNQuery(qp, k);
                    }
                    sw.stop;
                    sum += sw.peek.total!"usecs";
                }
                file4.writeln(cast(int)(sum/3)); 
        }}
        file4.close();
    }

    //fixed k, D, Varied N
    File file5 = File("QuadTreeKNNVaried_N.csv", "w");{
        file5.writeln("Const_k,N,Const_D,Time(us)");
        const int k = 10;
        const int D = 2;
        static foreach (N; [1, 50, 100, 200, 400, 800, 1600, 3200, 6400, 12800]){{
           file5.write(k,",",N,",",D,",");
                ulong sum = 0;
                foreach (round; 0..3)
                {
                    auto trainingPoints = getGaussianPoints!D(N);
                    auto testingPoints = getUniformPoints!D(100);
                    auto testTree = QuadTree(trainingPoints);
                    auto sw = StopWatch(AutoStart.no);
                    sw.start; //start my stopwatch
                    foreach(const ref qp; testingPoints){
                        testTree.KNNQuery(qp, k);
                    }
                    sw.stop;
                    sum += sw.peek.total!"usecs";
                }
                file5.writeln(cast(int)(sum/3)); 
        }}
        file5.close();
    }

    //fixed D, N varied K
    File file6 = File("QuadTreeKNNVaried_k.csv", "w");{
        file6.writeln("k,Const_N,Const_D,Time(us)");
        const int N = 1000;
        const int D = 2;
        static foreach (k; 0..10){{
           file6.write(k,",",N,",",D,",");
                ulong sum = 0;
                foreach (round; 0..3)
                {
                    auto trainingPoints = getGaussianPoints!D(N);
                    auto testingPoints = getUniformPoints!D(100);
                    auto testTree = QuadTree(trainingPoints);
                    auto sw = StopWatch(AutoStart.no);
                    sw.start; //start my stopwatch
                    foreach(const ref qp; testingPoints){
                        testTree.KNNQuery(qp, k);
                    }
                    sw.stop;
                    sum += sw.peek.total!"usecs";
                }
                file6.writeln(cast(int)(sum/3)); 
        }}
        file6.close();
    }    
}
