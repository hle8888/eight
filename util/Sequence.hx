package util;

class Sequence {
    var steps:Array<{ name:String, func:Sequence->Void }>;
    var index:Int = 0;
    var namedSteps:Map<String, Int>;
    var running:Bool = false;

    public function new() {
        steps = [];
        namedSteps = new Map();
    }

    public function then(fn:Sequence->Void, name:String=null):Sequence {
        steps.push({ name: name, func: fn });
        if (name != null) namedSteps.set(name, steps.length - 1);
        return this;
    }

    public function next():Void {
        index++;
        if (index < steps.length)
            runStep();
        else
            running = false;
    }

    public function step(name:String):Void {
        var i = namedSteps.get(name);
        if (i != null) {
            index = i;
            runStep();
        }
    }

    public function restart():Void {
        index = 0;
        running = true;
        runStep();
    }

    private function runStep():Void {
        if (index >= 0 && index < steps.length) {
            var step = steps[index];
            step.func(this);
        } else {
            running = false;
        }
    }
}
