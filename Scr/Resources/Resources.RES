        ��  ��                  �  @   ��
 S P R I T E S H A D E R . X M L         0 	        <Shader>
	<VertexShader>
	<Code>
		<![CDATA[
			#version 110
			attribute float IndxAttrib;

			uniform vec4 PosTC[64]; 
			uniform vec4 QuadData[64]; 
			
			varying vec4 InterpolatedData;
			varying vec4 Data1;
			varying vec4 Data2;
			varying vec4 Data3;
			varying vec4 Data4;
			varying vec2 Texcoord;

			void main( void )
			{
				int VertexId = int(IndxAttrib);
				int QuadId = ((VertexId)/4)*4;
				InterpolatedData = QuadData[VertexId];

				Data1 = QuadData[QuadId+0];
				Data2 = QuadData[QuadId+1];
				Data3 = QuadData[QuadId+2];
				Data4 = QuadData[QuadId+3];

				Texcoord = PosTC[VertexId].zw;
				gl_Position = vec4(PosTC[VertexId].xy, -1.0, 1.0);
			}
		]]>
		</Code>
	</VertexShader>
	
	<FragmentShader>
		<Code>
		<![CDATA[
			#version 110
			varying vec2 Texcoord;
			varying vec4 InterpolatedData;
			
			uniform sampler2D Map0;
			
			void main(void)
			{
				gl_FragColor = texture2D(Map0, Texcoord.xy)*InterpolatedData;
			}
		]]>
		</Code> 
	</FragmentShader>
</Shader>
,  <   ��
 T E X T S H A D E R . X M L         0 	        ﻿<Shader>
	<VertexShader>
		<Code>
		<![CDATA[
			#version 120
			attribute float IndxAttrib;

			uniform vec4 PosTC[64]; 
			uniform vec4 QuadData[64]; 
			uniform vec4 Params[4];
			
			varying vec4 InterpolatedData;
			varying vec4 Data1;
			varying vec2 Texcoord;
			varying float Grade;

			void main( void )
			{
				int VertexId = int(IndxAttrib);
				int QuadId = ((VertexId)/4)*4;
				Data1 = QuadData[QuadId+0];

				
				vec2 TC = vec2(PosTC[VertexId].z,1.0-PosTC[VertexId].w);
				Texcoord = TC*Data1.zw+Data1.xy;
			////		Grade = (PosTex.w-PosTexCoord[QuadId+2].w-Data1.z)/(PosTexCoord[QuadId+0].w-PosTexCoord[QuadId+2].w-Data1.z*2); 

				//Grade = TexCoordArray[VertexId-QuadId].y  * (1.0+Params[0].z*2.0*Data1.w)-Params[0].z*Data1.w;				
				//Grade = (Texcoord.y-(Data1.w+Data1.y)-Params[0].z)/(Data1.y-Data1.w+Data1.y)-Params[0].z*2.0);
				//Grade = (-TexCoordArray[VertexId-QuadId].y+1.0+Data1.y/Data1.w*2.0+Params[0].z/Data1.w)/(-Params[0].z*2.0);
			//Grade = (1.0-TexCoordArray[VertexId-QuadId].y)/(1.0+2.0*Params[0].z/Data1.w)+1.0/(Data1.w/Params[0].z+2.0);
				//	Grade = (-TexCoordArray[VertexId-QuadId].y+1.0-Params[0].z/(-Data1.w))/(1.0-Params[0].z/(-Data1.w)*2.0);
				Grade = (Params[0].z + Data1.w - Data1.w * TC.y) / (2.0 * Params[0].z + Data1.w);
				gl_Position = vec4(PosTC[VertexId].xy, -1.0, 1.0);
			}
		]]>
		</Code>
	</VertexShader>
	
	<FragmentShader>
		<Code>
		<![CDATA[
			#version 110
			uniform sampler2D Map0;

			varying vec2 Texcoord;
			varying float Grade;
			
			uniform vec4 Params[4];
			
			void main( void )
			{
				gl_FragColor = texture2D(Map0, Texcoord.xy);
				float dist = texture2D(Map0, Texcoord.xy).r;
				float k = min(Params[0].y,Params[0].x);
				vec3 Color = mix(Params[1].xyz, Params[2].xyz, Grade); 
				Color = mix(Color, Params[3].xyz, smoothstep(0.5 - k - Params[0].y,0.5 - k - Params[0].y, dist)*(1.0-smoothstep(0.5 - k,0.5 + k, dist)));
				gl_FragColor = vec4(Color,Params[1].w*smoothstep(0.5 - Params[0].x - Params[0].y,0.5 + Params[0].x - Params[0].y, dist));
			}
		]]>
		</Code> 
	</FragmentShader>
</Shader>
�      �� ��     	        (      0                                   *** ;;; DDD KKK XXX iii yyy ��� ��� ��� ��� ��� ��� wwwwwwwwwwwwfffffffffffUDDDDDDDDDDDD   }�  *� *`:P��� ��P?�O�
������?�O���
��?�O����q?�O��
��wr?�O�  
����?�O�  
����?�O�  
��Z�?�o�  
���?�p  
����?��0  
����?��   
� ^� *{�   
�         
�          
�         "#332"" 4DDDDUUTDDDCEUffffffffUUfgwwwwwwwwwf                                                                        (      �� ��     	        (                                            666 ;;; @@@ BBB EEE HHH MMM RRR TTT VVV ��� ��������w�����wv                        
���� ����  �  ��� �  ���  ����  �                         DC2Vw����we������̺                                                �      �� ��     	        (       @                                         			 


                        !!! ### %%% ''' ))) ,,, --- /// 000 111 222 333 444 555 666 777 888 999 ::: ;;; <<< === >>> ??? @@@ AAA BBB CCC DDD EEE FFF GGG HHH III JJJ KKK LLL MMM NNN OOO PPP QQQ RRR SSS TTT UUU VVV WWW XXX YYY ZZZ [[[ \\\ ]]] ^^^ ___ ``` aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp rrr sss uuu xxx }}} ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ���                                                                                                                                                                                                                                                                                                                                                                                                                                                 KLLLMMMNNNNNNNNNNMMMLLLKKJJJIHHGEFFFGGGGGGGHHGGGGGGGFFFEDDDCCBAA====>>>?????????>>>>===<<<;;:99877778888888888888888777665544332-.//3;300000005KT=////GH=*(;C?#"D���Xuxp}0�qtso  ^�����Y  
h+  l   [ [ V [   �������   +J    (J  [ [ V [   R�������N  TJc d [ [ V [   v��mn��m  d4W9c D [ [ V [  ���" 4��~ G Y [coE [ [ V [  ��� *��� 0& a  *+ [ [ V [  =]]  %��� F�rrrrr` [ [ V [        %��� Ob [ [ V [        %��� M       \ [ [ V [        %��� Bb]]b \ [ [ V [        %��� $2 |<;{
K [ `
S \        %��� U Y	e /) [ @DI [        %���  `)kj;b [ ]t(W        %���  G#%,Z  [  C        %���  "_   R/  [ Y  G'        %���  DiS^	  �z�n7_d        %���    3wyH    
\5          %���                           %���                            %���                            `lQ                             	      !(.0245678899998876431/,$+0469;=?ABDEFFGGGGFFECBA><:852.';?CEHJNPRTUWXYYYYYXWVUSQNLIGDA=:FINQTVZ\_acdfgggggfedb`^[YUSOLHE                                                                                                                                0   0   �� M A I N I C O N         0	               �      (         �   