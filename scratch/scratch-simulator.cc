/* -*- Mode:C++; c-file-style:"gnu"; indent-tabs-mode:nil; -*- */
/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation;
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/csma-module.h"
#include "ns3/internet-module.h"
#include "ns3/point-to-point-module.h"
#include "ns3/applications-module.h"
#include "ns3/ipv4-global-routing-helper.h"
#include "ns3/netanim-module.h"
#include "ns3/helics-helper.h"
#include <iostream>
#include <memory>
#include <string>
#include <vector>
#include <array>
#include <cstring>
#include <numeric>
#include <cstdlib>
#include <stdio.h>
#include <sstream>
#include <fstream>
#include <algorithm>
#include <cctype>
#include "helics/core/helicsCLI11.hpp"
#include "ns3/config-store-module.h"

using namespace ns3;
using namespace std;

//NS_LOG_COMPONENT_DEFINE("HelicsExample");

/*
 * The main() loop below represents the ns-3 model. The helics ns-3
 * integration will filter messages sent by MessageFederate instances by
 * creating HelicsApplication instances at Nodes. The name given to the
 * HelicsApplication should match a registered endpoint.
 */

void
read_config (string config_file_name, vector<string> &mgcs, vector<string> &inter_latency,
             vector<string> &inter_bandwidth, vector<vector<string>> &ied_names,
             vector<vector<string>> &ied_latency, vector<vector<string>> &ied_bandwidth)
{
  string default_latency = "0ms";
  string default_bandwidth = "1000Mbps";
  // Read from the text file
  ifstream MyReadFile (config_file_name);
  string line;
  // Use a while loop together with the getline() function to read the file line by line
  while (getline (MyReadFile, line, '\n'))
  {
    // Output the text from the file
    stringstream line_stream (line);
    vector<string> ied_vec;
    vector<string> latency_vec;
    vector<string> bandwidth_vec;
    int j = 0;
    while (line_stream.good ())
    {
      string item_str;
      getline (line_stream, item_str, ',');
      if (j == 0)
      { // first item in row: mgc name
        stringstream item_stream (item_str);
        int k = 0;
        while (item_stream.good ())
        {
          string prop_str;
          getline (item_stream, prop_str, ':');
          if (k == 0)
          {
            mgcs.push_back (prop_str);
          }
          if (k == 1)
          {
            inter_latency.push_back (prop_str);
          }
          if (k == 2)
          {
            inter_bandwidth.push_back (prop_str);
          }
          k++;
        }
        //                mgcs.push_back(item_str);
      }
      else
      {
        if (line != "\n")
        {
          stringstream item_stream (item_str);
          int k = 0;
          while (item_stream.good ())
          {
            string prop_str;
            getline (item_stream, prop_str, ':');
            if (k == 0)
            {
              ied_vec.push_back (prop_str);
            }
            if (k == 1)
            {
              latency_vec.push_back (prop_str);
            }
            if (k == 2)
            {
              bandwidth_vec.push_back (prop_str);
            }
            k++;
          }
          if (k == 1)
          { // Set defaults for latency and bandwidth
            latency_vec.push_back (default_latency);
            bandwidth_vec.push_back (default_bandwidth);
          }
          if (k == 2)
          {
            bandwidth_vec.push_back (default_bandwidth);
          }
        }
      }
      j++;
    }
    ied_names.push_back (ied_vec);
    ied_latency.push_back (latency_vec);
    ied_bandwidth.push_back (bandwidth_vec);
    cout << line << endl;
  }
  cout << "Read array: " << endl;
  for (int i = 0; i < ied_names.size (); i++)
  {
    for (int j = 0; j < ied_names[i].size (); j++)
    {
      cout << ied_names[i][j] << endl;
    }
  }
  cout << "Read latencies: " << endl;
  for (int i = 0; i < ied_latency.size (); i++)
  {
    for (int j = 0; j < ied_latency[i].size (); j++)
    {
      cout << ied_latency[i][j] << endl;
    }
  }
  cout << "Read bandwidth: " << endl;
  for (int i = 0; i < ied_bandwidth.size (); i++)
  {
    for (int j = 0; j < ied_bandwidth[i].size (); j++)
    {
      cout << ied_bandwidth[i][j] << endl;
    }
  }
  // Close the file
  MyReadFile.close ();
}

void
dropLink (void)
{
  Config::Set (
      "/$ns3::NodeListPriv/NodeList/0/$ns3::Node/DeviceList/1/$ns3::PointToPointNetDevice/DataRate",
      StringValue ("1bps"));
}

int 
main (int argc, char *argv[])
{
//  NS_LOG_UNCOND ("Scratch Simulator");
  bool verbose = true;
  bool with_helics = true;
  int time_end_sim = 2;
  string config_file_name = "ns3_config.csv";
  //    vector<vector<string>> ept_ied{{"gen1", "inv1", "inv2", "met50_V"},
  //                                {"gen2", "inv3", "inv4", "met300_V"},
  //                                {"gen3", "inv5", "inv6", "met97_V"}};
  vector<vector<string>> ied_names;
  vector<vector<string>> ied_latency;
  vector<vector<string>> ied_bandwidth;
  vector<string> mgcs;
  vector<string> inter_latency;
  vector<string> inter_bandwidth;

  HelicsHelper helicsHelper;

  CommandLine cmd;
  cmd.AddValue ("time_end_sim", "duration of simulation in seconds", time_end_sim);
  cmd.AddValue ("verbose", "Tell echo applications to log if true", verbose);
  cmd.AddValue ("with_helics", "Set to false to run without helics", with_helics);
  cmd.AddValue ("config_file_name", "CSV file name for configuration file. ", config_file_name);
//  helicsHelper.SetupCommandLine (cmd);

  cmd.Parse (argc, argv);

  read_config (config_file_name, mgcs, inter_latency, inter_bandwidth, ied_names, ied_latency,
               ied_bandwidth);
}
