# 1.1.0

Due to problems with autoloading, you now need to manually assign a list of workers:

```ruby
Lowkiq.workers = [ ATestWorker, ATest2Worker ]
```
