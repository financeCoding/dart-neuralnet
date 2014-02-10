import 'dart:io';
import 'dart:math';


var learning_rate=.1;
void main() {
  var net = new Neural_Net(3, 2);
  net.wire_connections();
  List<double> sample_input = [1,1];
  List<double> expected_output = [0,0];
  List<double> sample_input2 = [1,0];
  List<double> expected_output2 = [1,1];
  List<double> sample_input3= [0,1];
  List<double> expected_output3= [1,1];
  List<double> sample_input4 = [0,0];
  List<double> expected_output4 = [0,0];
  for(int i = 0; i <100; i++){
    net.learn(sample_input, expected_output);
    net.learn(sample_input2, expected_output2);
    net.learn(sample_input3, expected_output3);
    net.learn(sample_input4, expected_output4);
  }
  

}

class Neural_Net
{
  List<Layer> layers = new List<Layer>();
  Neural_Net(int layers, int nodes_in_layer){
    for (int i = 0; i < layers; i++){
      this.layers.add(new Layer(nodes_in_layer));
    }
  }

  void learn(List<double> input, List<double> expected_output){
    run_net(input);
    //Compute Deltas
    for (int i = 0; i < layers.length; i++){
      var index = layers.length-1-i;
      if (layers[index].previousLayer != null){
        layers[index].compute_deltas(expected_output);
      }
    }
    for (int i = 1; i < layers.length; i++){
      layers[i].change_weights(); 
    }
    print_net();

  }
  
  void print_net(){
    for (int i = 0; i < layers.length; i++){
      var layer = layers[i];
      stdout.write('Delta values:');
      for (int j = 0; j < layers[i].neurons.length; j++){
        var neuron = layer.neurons[j];
        stdout.write(neuron.delta);
      }
      stdout.write('\n');
      stdout.write('Outputs:');
      for (int j = 0; j < layers[i].neurons.length; j++){
        var neuron = layer.neurons[j];
        stdout.write(neuron.output);
        if (j != layers[i].neurons.length-1){
          stdout.write(',');
        }
      }
      stdout.write('\n');
      stdout.write('Weights:');
      for (int j = 0; j < layers[i].neurons.length; j++){
        var neuron = layer.neurons[j];
        for (int k = 0; k <layer.neurons[j].input_connections.length; k++){
          stdout.write(neuron.input_connections[k].weight);
          stdout.write(',');
        }
          stdout.write(';');
      }
      
      stdout.write('\n');
      stdout.write('\n');
    }
  }
  
  void run_net(List<double> inputs){
    if (inputs.length != layers[0].neurons.length){
      print('Input size is not not compatable');
    }else{
      
      //Set up initial inputs
      for (int i=0; i < layers[0].neurons.length; i++){
        layers[0].neurons[i].output=inputs[i];
      }
      
      
      //Traverse through layers(except for first layer) and compute outputs
      for (int i = 1; i < layers.length; i++){
        layers[i].run_layer();
      }
    }
  }
  
  
  void wire_connections(){
    for (int i = 1; i < layers.length; i++){
      layers[i].add_input_layer(layers[i-1]);
    }
  }
  
  List<double> get_output(){
    List<double> rv = new List<double>();
    Layer output_layer = layers[layers.length-1];
    for(int i = 0; i < output_layer.neurons.length; i++){
      rv.add(output_layer.neurons[i].output);
    }
  }
  
}

class Layer
{
  int alpha = 1;
  Layer nextLayer = null;
  Layer previousLayer = null;
  List<Neuron> neurons = new List<Neuron>();
  Layer(int nodes_in_layer){
    for (int i = 0; i<nodes_in_layer; i++){
      neurons.add(new Neuron(this));
    }
    
  }
  void add_input_layer(Layer input_layer){
    previousLayer = input_layer;
    input_layer.nextLayer = this;
    for (int i = 0; i < neurons.length; i++){
      for (int j = 0; j < input_layer.neurons.length; j++){
        Connection connection = new Connection(input_layer.neurons[j], neurons[i]);
        neurons[i].add_input(connection);
        input_layer.neurons[j].add_output(connection);
      }
    }
  }

  void compute_deltas(List<double> expected){
      if (nextLayer == null){
        for (int i = 0; i < neurons.length; i++){
         neurons[i].compute_output_delta(expected[i]);
        }
      }else{
        for (int i = 0; i < neurons.length; i++){
          neurons[i].compute_delta();
        }
      }

  }

  void change_weights(){
    for (int i = 0; i < neurons.length; i++){
      neurons[i].change_weights();
      neurons[i].change_bias();
    }
  }

  
  void run_layer(){
    for(int i = 0; i<neurons.length; i++){
      neurons[i].calculate_output();
    }
  }
  
  Layer next(){
    return this.nextLayer;
  }
  
  Layer previous(){
    return this.previousLayer;
  }
  
}

class Neuron
{
 var alpha = 1;
  List<Connection> input_connections = new List<Connection>();
  List<Connection> output_connections = new List<Connection>();
  var bias;
  var net_input;
  var output;
  var delta;
  var layer;
   
  
  Neuron(Layer l){
    output = 0;
    bias = .5;
    layer = l;
  }
  
  double sigmoid(x){
    return 1/(1+pow(E,(-alpha*x)));
  }
  
  void add_input(Connection connection){
    input_connections.add(connection);
  }
  void add_output(Connection output){
    output_connections.add(output);
  }
  double calculate_net_input(){
    
    this.net_input = 0;
    for (int i = 0; i < input_connections.length; i++){
      var c = input_connections[i];
      net_input += c.weight * c.n_from.output;
    }
    net_input += bias;
  }
  
  void calculate_output(){
    calculate_net_input();
    this.output=this.sigmoid(net_input);
  }
  
  void compute_output_delta(var expected){
      //Compute output delta
      this.delta = 2*alpha*output*(1-output)*(expected-output);
      
  }
  void compute_delta(){
      //Compute normal delta
      var delta_sum = 0;
      for (int i = 0; i < layer.next().neurons.length;i++){
       Neuron nlayer_neuron = layer.next().neurons[i];
        delta_sum += nlayer_neuron.delta*this.output_connections[i].weight ;
      }
      this.delta = alpha*output*(1-output)*delta_sum;
  }

  void change_weights(){
    if (layer.previousLayer != null){
      for (int i = 0; i < input_connections.length; i++){
        input_connections[i].weight += input_connections[i].n_from.output * delta * learning_rate;
      }
    }
  }

  void change_bias(){
    bias += learning_rate * delta;
  }
}

class Connection
{
  Neuron n_from, n_to;
  double weight;
  Connection(Neuron n_from, Neuron n_to){
    var random = new Random();
    var rand_weight = random.nextDouble()-.5;
    this.n_from = n_from;
    this.n_to = n_to;
    this.weight = rand_weight;
  }
}