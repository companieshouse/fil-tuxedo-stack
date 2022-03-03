write_files:
  - path: /opt/oracle-instant-client/11.2.0.4.0/tnsnames.ora
    owner: root:root
    permissions: 0644
    content: |
      %{ for db in tnsnames }${ db.name } =
        (DESCRIPTION =
          (ADDRESS_LIST =
            (ADDRESS = (PROTOCOL = TCP)(HOST = ${ db.address })(PORT = ${ db.port }))
          )
          (CONNECT_DATA =
            (SERVICE_NAME = ${ db.service_name })
            (SERVER = DEDICATED)
          )
        )
      %{ endfor }
