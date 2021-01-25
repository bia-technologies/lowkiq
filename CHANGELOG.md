# 1.1.0

* Timestamps are float rather than int. #23
* Due to problems with autoloading, you now need to manually assign a list of workers. #22

```ruby
Lowkiq.workers = [ ATestWorker, ATest2Worker ]
```
