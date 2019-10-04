RSpec.describe Lowkiq::Splitters::ByNode do
  let(:number_of_nodes) { 3 }
  let(:node_number) { 1 }
  let(:threads_per_node) { 5 }

  let(:splitter) { described_class.new 3, 1, 5 }

  it "not enough items" do
    fake_handlers = [
      :w0_sh0, :w0_sh1, :w0_sh2, :w0_sh3,
      :w1_sh0, :w1_sh1, :w1_sh2, :w1_sh3, :w1_sh4,
      :w2_sh0,
      :w3_sh0, :w1_sh1, :w1_sh2,
    ]
    expect( splitter.call fake_handlers ).to eq [[:w0_sh1],
                                                 [:w1_sh0],
                                                 [:w1_sh3],
                                                 [:w3_sh0],
                                                 # [] - на пятый тред не хватило работы
                                                ]
  end

  it "enough items" do
    fake_handlers = [
      :w0_sh0, :w0_sh1, :w0_sh2, :w0_sh3,
      :w1_sh0, :w1_sh1, :w1_sh2, :w1_sh3, :w1_sh4,
      :w2_sh0,
      :w3_sh0, :w1_sh1, :w1_sh2,
      :w4_sh0, :w4_sh1, :w4_sh2, :w4_sh3, :w4_sh4,
      :w5_sh0, :w5_sh1, :w5_sh2, :w5_sh3, :w5_sh4,
      :w6_sh0, :w6_sh1, :w6_sh2, :w6_sh3, :w6_sh4,
      :w7_sh0, :w7_sh1, :w7_sh2, :w7_sh3, :w7_sh4,
      :w8_sh0, :w8_sh1, :w8_sh2, :w8_sh3, :w8_sh4,
      :w9_sh0, :w9_sh1, :w9_sh2, :w9_sh3, :w9_sh4,
    ]
    expect( splitter.call fake_handlers ).to eq [[:w0_sh1, :w4_sh3, :w7_sh3],
                                                 [:w1_sh0, :w5_sh1, :w8_sh1],
                                                 [:w1_sh3, :w5_sh4, :w8_sh4],
                                                 [:w3_sh0, :w6_sh2, :w9_sh2],
                                                 [:w4_sh0, :w7_sh0],
                                                ]
  end
end
