class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @viewController = ViewController.alloc.init
    @window.rootViewController = @viewController
    @window.makeKeyAndVisible
    true
  end
end

class ViewController < UIViewController
  attr_accessor :textView
  def viewDidLoad
    super
      self.textView = UITextView.alloc.initWithFrame(self.view.frame)
      self.view.addSubview(self.textView)
    self.view.backgroundColor = UIColor.whiteColor
  end

  def viewDidAppear(animated)
    super
    testUserConvosRubyMotionParsingPerformance
  end

  def testUserConvosRubyMotionParsingPerformance
    filePath = NSBundle.mainBundle.pathForResource('convos', ofType: 'json')
    jsonData = NSData.dataWithContentsOfFile(filePath)
    jsonObject = NSJSONSerialization.JSONObjectWithData(jsonData, options: 0, error: nil)
    self.measure do
      resp = CSUserConvosResponse.new
      resp.updateWithJSON(jsonObject)
      puts "resp: #{resp}"
    end
  end

  def measure
    times = []
    10.times do
      startTime = CFAbsoluteTimeGetCurrent()
      yield
      endTime = CFAbsoluteTimeGetCurrent()
      times << (endTime - startTime)
    end
    avg = times.inject{ |sum,el| sum + el}.to_f / times.size
    variance = times.inject(0.0) { |accum, i| accum + (i-avg)**2 }
    variance = variance/(times.size - 1).to_f
    stddev = Math.sqrt(variance)
    self.textView.text = "Measured [Time, seconds] average: #{avg}, relative standard deviation: #{stddev}, values: #{times}"
  end
end