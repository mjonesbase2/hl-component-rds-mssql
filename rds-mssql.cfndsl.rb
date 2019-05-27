CloudFormation do

    Description "#{component_name} - #{component_version}"
  
    az_conditions_resources('SubnetPersistence', maximum_availability_zones)
  
    tags = []
    tags << { Key: 'Environment', Value: Ref(:EnvironmentName) }
    tags << { Key: 'EnvironmentType', Value: Ref(:EnvironmentType) }
  
    extra_tags.each { |key,value| tags << { Key: key, Value: value } } if defined? extra_tags
  
    EC2_SecurityGroup "SecurityGroupRDS" do
      VpcId Ref('VPCId')
      GroupDescription FnJoin(' ', [ Ref(:EnvironmentName), component_name, 'security group' ])
      SecurityGroupIngress sg_create_rules(security_group, ip_blocks)
      Tags tags + [{ Key: 'Name', Value: FnJoin('-', [ Ref(:EnvironmentName), component_name, 'security-group' ])}]
    end
  
    RDS_DBSubnetGroup 'SubnetGroupRDS' do
      DBSubnetGroupDescription FnJoin(' ', [ Ref(:EnvironmentName), component_name, 'subnet group' ])
      SubnetIds az_conditional_resources('SubnetPersistence', maximum_availability_zones)
      Tags tags + [{ Key: 'Name', Value: FnJoin('-', [ Ref(:EnvironmentName), component_name, 'subnet-group' ])}]
    end
  
    RDS_DBParameterGroup 'ParametersRDS' do
      Description FnJoin(' ', [ Ref(:EnvironmentName), component_name, 'parameter group' ])
      Family family
      Parameters parameters if defined? parameters
      Tags tags + [{ Key: 'Name', Value: FnJoin('-', [ Ref(:EnvironmentName), component_name, 'parameter-group' ])}]
    end

    instance_username = defined?(master_username) ? master_username : FnJoin('', [ '{{resolve:ssm:', FnSub(master_login['username_ssm_param']), ':1}}' ])
    instance_password = defined?(master_password) ? master_password : FnJoin('', [ '{{resolve:ssm-secure:', FnSub(master_login['password_ssm_param']), ':1}}' ])
  
  
    RDS_DBInstance 'RDS' do
      DeletionPolicy deletion_policy if defined? deletion_policy
      DBInstanceClass Ref('RDSInstanceType')
      AllocatedStorage Ref('RDSAllocatedStorage')
      StorageType 'gp2'
      Engine engine
      EngineVersion engine_version
      DBParameterGroupName Ref('ParametersRDS')
      MasterUsername  instance_username
      MasterUserPassword instance_password
      DBSnapshotIdentifier  Ref('RDSSnapshotID')
      DBSubnetGroupName  Ref('SubnetGroupRDS')
      VPCSecurityGroups [Ref('SecurityGroupRDS')]
      MultiAZ Ref('MultiAZ')
      Tags  tags + [
        { Key: 'Name', Value: FnJoin('-', [ Ref(:EnvironmentName), component_name, 'instance' ])},
        { Key: 'SnapshotID', Value: Ref('RDSSnapshotID')},
        { Key: 'Version', Value: family}
      ]
    end
  
    record = defined?(dns_record) ? dns_record : 'mssql'
  
    Route53_RecordSet('DatabaseIntHostRecord') do
      HostedZoneName FnJoin('', [ Ref('EnvironmentName'), '.', Ref('DnsDomain'), '.'])
      Name FnJoin('', [ record, '.', Ref('EnvironmentName'), '.', Ref('DnsDomain'), '.' ])
      Type 'CNAME'
      TTL 60
      ResourceRecords [ FnGetAtt('RDS','Endpoint.Address') ]
    end
  
  end