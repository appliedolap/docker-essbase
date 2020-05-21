# Essbase Studio Configuration

Add this to the essbase-config.xml:

  <product productXML="BPMS">
    <tasks>
      <task>hubRegistration</task>
      <task>preConfiguration</task>
      <task>relationalStorageConfiguration</task>
    </tasks>
    <bean name="main">
      <bean name="customConfiguration">
        <property name="productDataLocation">BPMS/datafiles</property>
        <property name="relativePaths"/>
        <property name="relativePathsInstance">productDataLocation</property>
      </bean>
      <bean name="relationalStorageConfiguration">
        <bean name="MS_SQL_SERVER">
          <property name="createOrReuse">create</property>
          <property name="customURL">false</property>
          <property name="dbIndexTbsp"/>
          <property name="dbName">EPM_STUDIO</property>
          <property name="dbTableTbsp"/>
          <property name="encrypted">true</property>
          <property name="host">db</property>
          <property name="jdbcUrl">jdbc:weblogic:sqlserver://db:1433;databaseName=EPM_HSS;loadLibraryPath=/opt/Oracle/Middleware/wlserver_10.3/server/lib</property>
          <property name="password">y07pS80UH56tmk9p1Am2vldLAsKIpOc8Xhntrtc/6+s29NDcXfCDoWcP8pxMkf5u</property>
          <property name="port">1433</property>
          <property name="SSL_ENABLED">false</property>
          <property name="userName">sa</property>
          <property name="VALIDATESERVERCERTIFICATE">false</property>
        </bean>
      </bean>
      <property name="shortcutFolderName">Essbase/Essbase Studio</property>
    </bean>
  </product>

