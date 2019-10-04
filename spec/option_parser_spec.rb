RSpec.describe Lowkiq::OptionParser do
  it "defaults" do
    args = ["-r" "./lib/app.rb"]
    expect( Lowkiq::OptionParser.call args ).to eq({require: "./lib/app.rb"})
  end
end
