# Usage

+ `bundle exec ../../exe/lowkiq -r ./lowkiq.rb`
+ `bundle exec sidekiq -r ./sidekiq.rb`

# Results

5 threads, 100_000 jobs

+ lowkiq default: 155 sec
+ lowkiq +seq: 146 sec
+ lowkiq +hiredis: 80 sec
+ lowkiq +seq +hiredis: 65 sec
+ sidekiq: 15 sec
