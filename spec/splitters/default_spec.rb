RSpec.describe Lowkiq::Splitters::Default do
  let(:threads_per_node) { 5 }

  let(:splitter) { described_class.new 5 }

  it "not enough items" do
    fake_handlers = [
      :w0_sh0, :w0_sh1, :w1_sh0, :w2_sh0,
    ]
    expect( splitter.call fake_handlers ).to eq [[:w0_sh0],
                                                 [:w0_sh1],
                                                 [:w1_sh0],
                                                 [:w2_sh0],
                                                 # [] - на пятый тред не хватило работы
                                                ]
  end

  it "enough items" do
    fake_handlers = [
      :w0_sh0, :w0_sh1, :w0_sh2, :w0_sh3,
      :w1_sh0, :w1_sh1, :w1_sh2, :w1_sh3, :w1_sh4,
      :w2_sh0,
      :w3_sh0, :w1_sh1, :w1_sh2,
    ]
    expect( splitter.call fake_handlers ).to eq [[:w0_sh0, :w1_sh1, :w3_sh0],
                                                 [:w0_sh1, :w1_sh2, :w1_sh1],
                                                 [:w0_sh2, :w1_sh3, :w1_sh2],
                                                 [:w0_sh3, :w1_sh4],
                                                 [:w1_sh0, :w2_sh0],
                                                ]
  end
end
