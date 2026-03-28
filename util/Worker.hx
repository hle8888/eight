package util;
import sys.thread.Thread;
import sys.thread.Mutex;

class Worker {
    private static var mutex = new Mutex();
    public static var tasks:Array<Void->Void> = [];
    public static function run() {
        Thread.create(function() {
            while (true) {
                mutex.acquire();
                
                var task = tasks.shift();
                if (task != null) {
                    task();
                }

                mutex.release();
                Sys.sleep(0.1); 
            }
        });
    }

    public static function runTask(task:Void->Void) {
        mutex.acquire();
        tasks.push(task);
        mutex.release();
    }
}