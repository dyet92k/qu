require 'spec_helper'

describe Qu::Worker do
  let(:job) { Qu::Job.new('1', SimpleJob, []) }

  describe 'queues' do
    before do
      Qu.stub!(:queues).and_return(%w(c a b))
    end

    it 'should use all queues from backend with an asterisk' do
      Qu::Worker.new('*').queues.should == %w(a b c)
    end

    it 'should append other queues with an asterisk' do
      Qu::Worker.new('b', '*').queues.should == %w(b a c)
    end

    it 'should properly handle queues passed as an array to the initializer' do
      Qu::Worker.new(%w(b *)).queues.should == %w(b a c)
    end
  end

  describe 'work' do
    before do
      Qu.stub!(:reserve).and_return(job)
    end

    it 'should reserve a job' do
      Qu.should_receive(:reserve).with(subject).and_return(job)
      subject.work
    end

    it 'should perform the job' do
      job.should_receive(:perform)
      subject.work
    end
  end

  describe 'work_off' do
    it 'should work all jobs off the queue' do
      Qu.should_receive(:reserve).exactly(4).times.with(subject, :block => false).and_return(job, job, job, nil)
      subject.work_off
    end
  end

  describe 'running?' do
    it 'should default to false' do
      subject.running?.should be_false
    end
  end

  describe 'start' do
    before do
      subject.stub(:running?).and_return(false)
    end

    it 'should register worker with the backend' do
      Qu.backend.should_receive(:register_worker).with(subject)
      subject.start
    end
  end

  describe 'stop' do
    it 'should unregister worker' do
      Qu.backend.should_receive(:unregister_worker)
      subject.stop
    end

    it 'should set running to false' do
      subject.instance_variable_set(:@running, true)
      subject.running?.should be_true
      subject.stop
      subject.running?.should be_false
    end
  end

  describe 'pid' do
    it 'should equal process id' do
      subject.pid.should == Process.pid
    end

    it 'should use provided pid' do
      Qu::Worker.new(:pid => 1).pid.should == 1
    end
  end

  describe 'id' do
    it 'should return hostname, pid, and queues' do
      worker = Qu::Worker.new('a', 'b', :hostname => 'quspec', :pid => 123)
      worker.id.should == 'quspec:123:a,b'
    end

    it 'should not expand star in queue names' do
      Qu::Worker.new('a', '*').id.should =~ /a,*/
    end
  end

  describe 'hostname' do
    it 'should get hostname' do
      subject.hostname.should_not be_empty
    end

    it 'should use provided hostname' do
      Qu::Worker.new(:hostname => 'quspec').hostname.should == 'quspec'
    end
  end

  describe 'attributes' do
    let(:attrs) do
      {'hostname' => 'omgbbq', 'pid' => 987, 'queues' => ['a', '*']}
    end

    it 'should return hash of attributes' do
      Qu::Worker.new(attrs).attributes.should == attrs
    end
  end
end
